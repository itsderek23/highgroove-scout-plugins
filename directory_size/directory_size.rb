class DirectorySize < Scout::Plugin
  TEST_USAGE = "#{File.basename($0)} directory DIRECTORY max_size MAX_SIZE"

  def self.escape(param)
    String(param).gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/, '\\').
                  gsub(/\n/, "'\n'").
                  sub(/^$/, "''")
  end
  
  def run
    du_output    = `du -sk '#{self.class.escape(@options["directory"])}'`
    if du_output =~ /\A\s*(\d+)\b/
      report = { :report => { :command => @options["directory"],
                              :size    => $1 },
                 :alerts => Array.new }
      if report[:report][:size].to_i > @options["max_size"].to_i
        report[:alerts] << { :subject => "Maximum Size Exceeded " +
                                         "(#{report[:report][:size].to_s} K)" }
      end
      report
    else
      raise "Size not found"
    end
  rescue
    { :error => { :subject => "Couldn't use `du` as expected.",
                  :body    => $!.message + " (#{du_output})" } }
  end
end
