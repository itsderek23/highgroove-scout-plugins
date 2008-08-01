require "time"

class MerbRequests < Scout::Plugin
  
  def run
    begin
      require "elif"
    rescue LoadError
      begin
        require "rubygems"
        require "elif"
      rescue LoadError
        return { :error => { :subject => "Couldn't load Elif.",
                             :body    => "The Elif library is required by " +
                                         "this plugin." } }
      end
    end
    
    if @options["log"].strip.length == 0
      return { :error => { :subject => "A path to the log file wasn't provided." } }
    end

    report = { :report => { :slow_request_count => 0,
                            :request_count => 0,
                            :average_request_length => nil},
               :alerts => Array.new }

    last_completed = true
    last_request_time = 0.0
    last_request_slow = false
    slow_requests = ''
    total_request_time = 0.0
    request = ''
    Elif.foreach(@options["log"]) do |line|

      # a typical line looks like:
      # ~ {:dispatch_time=>0.024486, :action_time=>0.023406, :before_filters_time=>0.00648, :after_filters_time=>2.1e-05}
      # since we have no way of knowing the time of this action, we're going
      # to cheat and store the line itself as our last_completed flag. 
      # Hopefully they are unique enough to give us some data when
      # reading back through the log.
      break if last_completed == @memory["last_completed"]

      puts "matching: #{line}"
      
      if line =~ /^~ \{:dispatch_time=>(\d+\.\d+), :action_time=>(\d+\.\d+).+\}\Z/
        puts "matching action line: #{line}"
        dispatch_time_completed = $1.to_f
        action_time_completed   = $2.to_f
        report[:report][:request_count] += 1
        request_time = dispatch_time_completed + action_time_completed
        last_request_time = request_time
        total_request_time += request_time

        if @options["max_request_length"].to_f > 0 and request_time > @options["max_request_length"].to_f
          last_request_slow = true    # flag it
        end 

        # set the last_completed line only if it hasn't been set
        last_completed = line if last_completed.nil?
      end # request should be analyzed
      if line =~ /^~ Request: (\S+)\Z/
        request = $1
        if last_request_slow
          report[:report][:slow_request_count] += 1
          slow_requests += "#{request}\n"
          slow_requests += "Time: " + last_request_time.to_s + " sec" + "\n\n"
          last_request_slow = false   # reset it
        end
      end
    end
    
    # store the last+completed line in memory
    report[:memory] = {"last_completed" => last_completed}
    
    # Create a single alert that holds all of the requests that exceeded the +max_request_length+.
    if report[:report] and (count = report[:report][:slow_request_count].to_i and count > 0)
      report[:alerts] << {:subject => "Maximum Time(#{@options["max_request_length"].to_s} sec) exceeded on #{count} #{count > 1 ? 'requests' : 'request'}",
                          :body => slow_requests}
    end
    # Calculate the average request time if there are any requests
    if report[:report][:request_count] > 0
      avg = total_request_time/report[:report][:request_count]
      report[:report][:average_request_length] = sprintf("%.2f", avg)
    end
    report
  rescue
    { :error => { :subject => "Couldn't parse log file.",
                  :body    => $!.message } }
  end
end
