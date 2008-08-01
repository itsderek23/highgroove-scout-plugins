class RailsSessionMonitor < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} days_for_old_sessions DAYS_FOR_OLD_SESSIONS path_to_app PATH_TO_APP rails_env RAILS_ENV"

  def run
    ENV['RAILS_ENV'] = @options['rails_env']
    # Ensure require options are provided
    if @options['rails_env'].nil?
      return { :error => {:subject => "Required option not provided",
                          :body    => "Please specify the Rails environment (ie: production, development, test)."}}
    elsif @options['path_to_app'].nil?
      return { :error => {:subject => "Required option not provided",
                          :body    => "The full path to your Rails application is required (ex: /var/www/apps/APP_NAME/current)."}}
    elsif @options['days_for_old_sessions'].nil?
      return { :error => {:subject => "Required option not provided",
                          :body    => "The Days for Old Sessions option must be provided. Sessions older than this amount will be deleted."}}
    end
    # Load the Rails Env
    require "#{@options['path_to_app']}/config/environment"
    
    total = CGI::Session::ActiveRecordStore::Session.count
    old = CGI::Session::ActiveRecordStore::Session.count(["updated_at < ?", @options['days_for_old_sessions'].to_i.days.ago ])
    
    {
      :report => {
        :total => total,
        :old => old
      }
    }
  rescue
    { :error => {:subject => "Unable to Monitor Rails Sessions", 
      :body => "The following exception was raised:\n\n#{$!.message}\n\n#{$!.backtrace}"}}
  end
end