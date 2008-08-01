class LoadAverages < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} max_load MAX_LOAD"
  
   def run
    data = {}
    data[:alerts] = []
    if `uptime` =~ /load average(s*): ([\d.]+)(,*) ([\d.]+)(,*) ([\d.]+)\Z/
      data[:report] = { :last_minute          => $2,
                        :last_five_minutes    => $4,
                        :last_fifteen_minutes => $6 }
    else
      raise "Unexpected output format"  
    end
    if @options['max_load'] and data[:report][:last_minute].to_f > @options['max_load'].to_f
      data[:alerts] << {:subject => "Maximum Load Exceeded (#{data[:report][:last_minute]})"}
    end
    data
  rescue
    {:error => {:subject => "Couldn't use `uptime` as expected.", :body => $!.message} }
  end
end