require "time"

class RailsRequestsSyslogger < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} log LOG max_request_length MAX_REQUEST_LENGTH last_run LAST_RUN"
  
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
      return { :error => { :subject => "A path to the Rails log file wasn't provided." } }
    end

    report = { :report => { :slow_request_count => 0,
                            :request_count => 0,
                            :average_request_length => nil},
               :alerts => Array.new }
    
    last_completed     = Hash.new
    slow_requests      = String.new
    total_request_time = 0.0
    Elif.foreach(@options["log"]) do |line|
      if line =~ /(\S+): Completed in (\d+\.\d+) .+ \[(\S+)\]\Z/
        last_completed[$1] = [$2.to_f, $3]
      elsif line =~ /(\S+): Processing .+ at (\d+-\d+-\d+ \d+:\d+:\d+)\)/ and
            last_completed.include? $1
        completed       = last_completed[$1]
        time_of_request = Time.parse($2)
        if time_of_request < (@last_run || (@options["last_run"] ? Time.parse(@options["last_run"]) : Time.now))
          break
        else
          report[:report][:request_count] += 1
          total_request_time += completed.first.to_f
          if @options["max_request_length"].to_f > 0 and completed.first.to_f > @options["max_request_length"].to_f
            report[:report][:slow_request_count] += 1
            slow_requests += "#{completed.last}\n"
            slow_requests += "Time: #{completed.first} sec\n\n"
          end
        end # request should be analyzed
      end
    end
    
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
