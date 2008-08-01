class Uptime < Scout::Plugin
  def run
    data = {}
    if `uptime` =~ /up +([^,]+)/
      data[:report] = {:uptime => $1}
    else
      raise "Unexpected output format"  
    end
    data
  rescue
    {:error => {:subject => "Couldn't use `uptime` as expected.", :body => $!.message} }
  end
end