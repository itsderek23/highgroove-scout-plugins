require "etc"

class CheckPermissions < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} directory DIRECTORY [owner OWNER] "  +
                                                         "[group GROUP] " +
                                                         "[mode MODE]"

  def run
    report = {:files_tested => 0}
    failed = Array.new
    
    # adds a trailing '/' to the directory, which is appended
    # to the file page. 
    dir = @options["directory"]
    unless dir =~ /\/$/
      dir << '/'
    end
    
    Dir.foreach(@options["directory"]) do |file|
      next if File.directory? file
      st = File.stat(dir + file)
      unless @options["owner"].nil? or @options["owner"].empty? or
             @options["owner"] == Etc.getpwuid(st.uid).name
        failed << "File '#{file}' didn't have owner " +
                                "'#{@options['owner']}'"
      end
      unless @options["group"].nil? or @options["group"].empty? or
             @options["group"] == Etc.getgrgid(st.uid).name
        failed << "File '#{file}' didn't have group " +
                                "'#{@options['group']}'" 
      end
      
      unless @options["mode"].nil? or @options["mode"].empty?
        expected = @options["mode"].gsub(/[-rwx]{3}/) do |mode_str|
          mode_str.split("").inject(0) do |hex, m|
            hex + Hash[*%w[_ 0 r 4 w 2 x 1]][m].to_i
          end
        end
        actual = st.mode.to_s(8)[-expected.size..-1]
        unless actual == expected
          failed << "File '#{file}' had a mode of '#{actual}' " +
                                  "instead of the expected '#{expected}'" 
        end
      end
      
      report[:files_tested] += 1
    end
    alerts = Array.new
    if failed.any?
      alerts << {:subject => "#{failed.size} file(s) failed permission checks",
                 :body => "Directory: #{dir}<br/><br/>" + failed.join('<br/><br/>')}
    end
    report[:failures] = failed.size
    {:report => report, :alerts => alerts}
  rescue
    { :error => { :subject => "Couldn't determine file stats.",
                  :body    => $!.message + '<br/><br/>' + $!.backtrace.join.to_s } }
  end
end
