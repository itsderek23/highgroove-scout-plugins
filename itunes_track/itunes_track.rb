class ItunesTrack < Scout::Plugin
  APPLESCRIPT = <<-END_AS
  tell application "iTunes"
    try
        if not (exists current track) then return
        get name of current track
    end try
  end tell
  END_AS

  def run
    @process = @options["applescript_executable"] || "osascript"
    current_track = IO.popen(@process, "r+") do |as|
      as << APPLESCRIPT
      as.close_write
      as.read
    end
    report = {}
    alert_user = @memory[:no_track].nil?
    if current_track.empty? and alert_user
      report[:alerts] = [{:subject => "Your mac is currently tuneless!"}]
      report[:memory] = {:no_track => true}
    elsif current_track.empty? and !alert_user
      report[:memory] = {:no_track => true}
    else
      report[:track_name] = current_track
      report[:memory] = {:no_track => nil}  
    end
    report

  rescue Exception
    { :error => { :subject => "Couldn't use `#{@process}` as expected.",
                  :body    => "An exception was thrown:  #{$!.message}" } }
  end
end
