require "time"

class Feedburner < Scout::Plugin
  
  TEST_USAGE = "#{File.basename($0)} feed FEED"
  
  def require_libs
    require 'open-uri'
    require 'hpricot'
  end
  
  def run
    begin
      require_libs
    rescue LoadError
      begin
        require "rubygems"       
        require_libs
      rescue LoadError
        return { :error => { :subject => "Couldn't load required libraries.",
                             :body    => "Please see the required libaries in the README file" } }
      end
    end
    
    # The following attributes are required:
    # - feed
    if [@options["feed"]].map { |opt| opt.strip.length}.find { |v| v.zero? }
      return { :error => { :subject => "The feed must be provided." } }
    end
    
    # grabs data from the current day
    data = get_data(@options["feed"])
    { :report => data.merge({:scout_time => Time.parse(data['date'])}) }
  rescue
    { :error => {:subject => "FeedBurner data could not be collected",
                 :body    => "#{$!.message}\n\n#{$!.backtrace}"}
    }
  end # run
  
  private
  
  # Returns a 2-element hash with the circulation and feed hits
  def get_data(feed)
    res = open("http://api.feedburner.com/awareness/1.0/GetFeedData?uri=#{feed}").read
    hp = Hpricot(res)
    if hp.at("rsp").attributes['stat'] == "ok"
      parse_feedburner(res)
    else
      err = hp.at("err").attributes["msg"]
      raise "Unable to get data: #{err}"
    end
  end
  
  def parse_feedburner(data)
   doc = Hpricot.parse(data)
   result = {}

   entry = (doc/"rsp/feed/entry").first

   result['date'] = entry.attributes['date']
   result['circulation'] = entry.attributes['circulation']
   result['hits'] = entry.attributes['hits']

   result
  end
    
end # Feedburner
