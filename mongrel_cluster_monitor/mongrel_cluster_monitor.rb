class MongrelClusterMonitor < Scout::Plugin
  def run
    mongrel_configuration_dir = @options["mongrel_cluster_configuration_dir"] || "/etc/mongrel_cluster/"
    mongrel_rails_command = @options["mongrel_rails_command"] || "mongrel_rails"
    to_return = {:alerts => [], :report => {}, :memory => {}}
    Dir.chdir(mongrel_configuration_dir) do
      configs = Dir.glob("*.{yml,conf}")

      unless configs.empty?        
        configs.each do |config|
          application_name = config.gsub(".conf", "").gsub(".yml", "")
          mongrel_status = `#{mongrel_rails_command} cluster::status -C #{mongrel_configuration_dir}/#{config}`
          if mongrel_status.empty? 
            raise "mongrel_rails command: `#{mongrel_rails_command}` not found or no status information available"
          elsif mongrel_status.include?("missing")
            if @memory[application_name]
              to_return[:alerts] << {:subject => "#{application_name} is still down. Attempting Start."}
              mongrel_start = `#{mongrel_rails_command} cluster::start -C #{mongrel_configuration_dir}/#{config}`
            else
              to_return[:alerts] << {:subject => "#{application_name} is down."}
              to_return[:memory][application_name] = Time.now
            end
            to_return[:report][application_name] = 0
          else
            to_return[:report][application_name] = 1
            to_return[:memory][application_name] = nil
          end
        end
      else
        to_return[:alerts] << {:subject => "No mongrel configuration files found."}
      end
    end
    return to_return  
  rescue Exception
    { :error => { :subject => "Couldn't monitor the server.",
                  :body    => "An exception was thrown:  #{$!.message}" } }
  end
end
