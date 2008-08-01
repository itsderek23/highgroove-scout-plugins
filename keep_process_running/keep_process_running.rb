# TODO: use alternate process open to catch STDOUT, STDERR for those 
# processes that use
class KeepProcessRunning < Scout::Plugin

  def run
    report = {:report => {}, :alerts => [], :memory => {}}
    process_to_monitor = @options["process_name"] || ""
    restart_action     = @options["restart_action"] || process_to_monitor
    
    # Search all running processes for the process (do not match the grep 
    # process nor the locally running scout client).
    ps_output = `ps auxww | grep "#{process_to_monitor}" | grep -v "grep" | grep -v "scout"`
    unless process_match = ps_output.to_a.first  # process not found
      # attempt to restart the process
      restart_output = `#{restart_action}`
      report[:alerts] << {:subject => "#{process_to_monitor} is not running. Restart reported: #{restart_output}"}
    else # process is running
      # if we wanted to parse fields we could:
      # fields = process_match.downcase.split
      report[:report][process_to_monitor] = 1
    end    
    return report  
  rescue Exception
    { :error => { :subject => "Could not keep the process running.",
                  :body    => "An exception was thrown:  #{$!.message}" } }
  end
end
