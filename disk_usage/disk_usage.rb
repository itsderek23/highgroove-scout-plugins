class DiskUsage < Scout::Plugin
  
  def run
    df_command   = @options["command"] || "df -h"
    df_output    = `#{df_command}`
    
    # normal line ex:
    # /dev/disk0s2   233Gi   55Gi  177Gi    24%    /
    
    # multi-line ex:
    # /dev/mapper/VolGroup00-LogVol00
    #                        29G   25G  2.5G  92% /

    df_lines      = df_output.to_a
    df_columns    = df_lines.first.downcase.sub("use%", "capacity").split
    df_data       = df_lines[1..-1]

    line_index = 1
    while !df_data.empty?
    df_data.each_with_index do |df_data_line, idx|
      puts df_data_line.split.size
      if df_data_line.split.size != 6  # we have a multiline
        df_data_line[idx] << df_data_line
      else
        df_data_lines << df_data_line
        line = ""
      end
    end
        
    puts df_data_lines
    # if df_output =~ /\A\s*(\S.*?)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*\z/
    #   puts $1
    # end
    # fields       = df_output.to_a.first.downcase.sub("use%", "capacity").split
    # report       = {:report => Hash.new, :alerts => Array.new}
    # puts df_output.to_a.inspect
    # all_fields   = if df_output.to_a[1].include?("%")
    #                  df_output.to_a[1] # first line
    #                else
    #                  df_output.to_a[1] + df_output.to_a[2] # both lines
    #                end
    # fields.zip(all_fields.split) do |name, value|
    #   puts "name: #{name}  value: #{value}"
    #   next unless %w[size used avail capacity].include? name
    #   report[:report][name.to_sym] = value
    # end
    
    max = @options["max_capacity"].to_i

    if max > 0 and report[:report][:capacity].to_i > max
      
      report[:alerts] << { :subject => "Maximum Capacity Exceeded " +
                                       "(#{report[:report][:capacity]})" }
    end
    report
  rescue
    { :error => { :subject => "Couldn't use `df` as expected.",
                  :body    => $!.message } }
  end
end
