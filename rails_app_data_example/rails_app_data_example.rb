class RailsAppDataExample < Scout::Plugin
  def run
    # load the rails app env
    require "#{@options['path_to_app']}/config/environment"
  
    data = Hash.new
    data[:shoutouts]   = Shoutout.count
    data[:votes]  = Vote.count
  
    {:report => data}
  rescue
    {:error => {:subject => "Couldn't retrieve app data as expected.", :body => $!.message} }
  end
end