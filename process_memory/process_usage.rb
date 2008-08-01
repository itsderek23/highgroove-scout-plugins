class ProcessUsage < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} command_name COMMAND_NAME max_memory_usage MAX_MEMORY_USAGE"
  
  MEM_CONVERSION = 1024
  
  def run
    ps_command   = @options['ps_command'] || "ps axucww"
    ps_output    = `#{ps_command}`
    fields       = ps_output.to_a.first.downcase.split
    memory_index = fields.index("rss")
    highest      =
      ps_output.grep(/#{Regexp.escape(@options["command_name"])}\s+$/i).
                map { |com| Float(com.split[memory_index]).abs }.max
    if highest
      report = { :report => { :command => @options["command_name"],
                              :memory  => (highest/MEM_CONVERSION).to_i } }
      max    = @options['max_memory_usage'].to_f * MEM_CONVERSION
      # Generates a new failure alert if a failure alert wasn't sent on the last run. 
      # If a failure alert was previously sent but a failure hasn't occured on this run, generates an alert
      # informing that the memory usage has dropped below the threshold.
      if exceeded?(max,highest) and !@memory[:failure]
        report[:alerts] = [{:subject => "Maximum Memory Exceeded (#{(highest/MEM_CONVERSION).to_i} MB)"}]
        report[:memory] = {:failure => true}
      elsif !exceeded?(max,highest) and @memory[:failure]
        report[:alerts] = [{:subject => "Maximum Memory Has Dropped Below Limit (#{(highest/MEM_CONVERSION).to_i} MB)"}]
        report[:memory] = {:failure => nil}
      else
        report[:memory] = @memory
      end
      report
    else
      { :error => { :subject => "Command not found.",
                    :body    => "No processes found matching " +
                                "#{@options['command_name']}." } }
    end
  rescue
    { :error => { :subject => "Couldn't use `ps` as expected.",
                  :body    => $!.message } }
  end
  
  def exceeded?(max,highest)
    (max > 0 and highest > max)
  end
end
