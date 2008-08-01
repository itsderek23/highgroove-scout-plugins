require "time"

class GoogleAnalytics < Scout::Plugin
  
  TEST_USAGE = "#{File.basename($0)} user USER password PASSWORD account ACCOUNT profile PROFILE offset OFFSET"
  
  USERAGENT = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
  LANGUAGE = 'en-US'
  
  def require_libs
    require 'net/http'
    require 'net/https'
    require 'uri'
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
    # - user
    # - password
    # - account
    # - profile
    if [@options["account"],@options["profile"],@options["user"],@options["password"]].map { |opt| opt.strip.length}.find { |v| v.zero? }
      return { :error => { :subject => "The user, password, account, and profile must be provided." } }
    end
    
    init_request_vars
    unless login
      return { :error => { :subject => "The user and/or password is invalid." } }
    end
    
    # grabs data from the current day
    data = visit_data(@options["account"],@options["profile"],Time.parse(Date.today.to_s).utc-(@options["offset"].to_i*60*60),Time.parse(Date.today.to_s).utc-(@options["offset"].to_i*60*60))
    
    { :report => data }
  rescue
    { :error => {:subject => "Google Analytics data could not be collected",
                 :body    => "#{$!.message}\n\n#{$!.backtrace}"}
    }
  end # run

  # Vars that will be sent along with the request
  def init_request_vars
    @user = @options["user"]
    @pass = @options["password"]
  end
  
  # Logs into Google Analytics. 
  # Returns true if successful, false otherwise. 
  # Sets +@cookies+ for future requests.
  def login
    par = {'continue' =>        'https://www.google.com/analytics/home/?et=reset&hl=' + LANGUAGE,
     'service' =>         'analytics',
     'nui' =>	          'hidden',
     'hl' =>              LANGUAGE,
     'GA3T'	=>	  'ouVrvynQwUs',
     'Email' =>           @user,
     'PersistentCookie'=> 'yes',
     'Passwd' =>          @pass}
  
    http = Net::HTTP.new("www.google.com", 443)
    http.use_ssl = true
    resp = nil
    http.start do |http|
      req = Net::HTTP::Post.new("/accounts/ServiceLoginBoxAuth")
      req.set_form_data(par)

      resp = http.request(req)
    end
   
    @cookies = resp.response['set-cookie'].split('; ')[0]
 
    if resp.code.to_i != 200
      false
    else
      true
    end
  end
  
  # Grabs the list of accounts for this user. Returns an Array of Hashes
  # that contains the account value and name.
  def list_accounts
    req = Hpricot(make_request('/analytics/home/?et=reset&hl=' + LANGUAGE))
    # some logins are redirected
    title = req.search("title/text()").first
    options = if title.to_s =~ /301/           
                url = req.search("a").first['href']
                req = Hpricot(make_request(url))
                req.search("//select[@id='account']/option")
              else
                req.search("select[@name='account_list']/option")
              end
   if options.empty?
     if req.search("iframe[@id='login']")
       raise "Unable to login to the Google Analytics with user [#{@options['user']}]. Please ensure the login and password is correct."
     end
   end
   accounts = []
   options.each do |opt|
   if opt['value'] != "0"
    acc = {}
    acc['value'] = opt['value']
    acc['name'] = opt.inner_html
    accounts << acc
   end
   end
   accounts
  end
  
  # Lists profiles available under the +account_id+.
  def list_profiles_for_account(account_id)
    req = Hpricot(make_request("/analytics/home/admin?vid=1100&scid=#{account_id}"))
    find_profiles(req)
  end
  
  def find_profiles(req)
    options = req.search("select[@name='profile_list']/option")
     profiles = []
     options.each do |opt|
     if opt['value'] != "0"
      prof = {}
      prof['value'] = opt['value']
      prof['name'] = opt.inner_html
      profiles << prof
     end
     end
     profiles
  end
  
  # Returns a 2-element hash with the number of visits and page_views over the specified range.
  def visit_data(account_name,profile_name,start_date,end_date)
    accounts = list_accounts
    account = accounts.find { |pair| pair["name"] == account_name }
    
    if account.nil?
      error = "Couldn't find the account with name: #{account_name}."
      if !accounts.any?
        error << " No accounts are available with the provided login information. Please ensure the user #{@options['user']} has access."
      else
        error << " #{accounts.size} Possible accounts: #{accounts.join(', ')}"
      end
      raise error
    end
    
    account_id = account["value"]
    
    profiles = list_profiles_for_account(account_id)
    profile  = profiles.find { |pair| pair["name"] == profile_name }
    
    raise "Couldn't find the profile with name: #{profile_name}" if profile.nil?
          
    profile_id = profile["value"]
    
    start_date = start_date.strftime("%Y%m%d")
    end_date   = end_date.strftime("%Y%m%d")
    
    req = Hpricot(make_request("/analytics/reporting/dashboard?id=#{profile_id}&pdr=#{start_date}-#{end_date}&cmp=average"))
    
    visits = (req/"//div[@id='VisitsSummary']//span[@class='primary_value']").inner_html.strip.gsub(/\D/,'').to_i
    page_views = (req/"//div[@id='PageviewsSummary']//span[@class='primary_value']").inner_html.strip.gsub(/\D/,'').to_i
    
    {"visits" => visits, "page_views" => page_views}
  end
  
  def make_request(address)
    raise ScriptError, "You should already be logged in!" unless @cookies
      
    headers = {
       'Cookie' => @cookies,
       'User-Agent' => USERAGENT
  	}
    response, body = nil
    http = Net::HTTP.new("www.google.com", 443)
    http.use_ssl = true
    http.start do |http|
     req = Net::HTTP::Get.new(address, headers)
     response = http.request(req)
     body = response.body
    end
  
   body
  end
  
  
    
    
end # GoogleAnalytics
