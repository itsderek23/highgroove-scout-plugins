class YahooTotalEntries < Scout::Plugin
  
  TEST_USAGE = "#{File.basename($0)} terms TERMS"
  
  def require_libs
    require 'net/http'
    require 'hpricot'
    require 'cgi'
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
    # - term
    if [@options["terms"]].map { |opt| opt.strip.length}.find { |v| v.zero? }
      return { :error => { :subject => "A search term must be provided." } }
    end
    
    # grabs data from the current day
    data = get_data(@options["terms"])
    { :report => data }
  rescue
    { :error => {:subject => "Yahoo! data could not be collected",
                 :body    => "#{$!.message}\n\n#{$!.backtrace}"}
    }
  end # run
  
  private
  
  # Returns a 2-element hash with the circulation and feed hits
  def get_data(terms)
    # don't think a unique id is required
    app_id = "unique_app_id"
    
    terms = terms.split(',')
    results = {}
    
    terms.each do |t|
      query = CGI::escape(t)
      url ="http://api.search.yahoo.com/WebSearchService/V1/webSearch?appid=#{app_id}&query=#{query}"
      res = Net::HTTP.get_response(URI.parse(url))
      doc = Hpricot(res.body)
      
      total = doc.at("resultset")['totalresultsavailable']
      
      results[t.gsub("\"",'').strip] = total
      
    end # terms.each
    
    results
  end
    
end # Feedburner
