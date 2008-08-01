class MemoryProfiler < Scout::Plugin
  def run
    mem_info = {}
    `cat /proc/meminfo`.each do |line|
      _, key, value = *line.match(/^(\w+):\s+(\d+)\s/)
      mem_info[key] = value.to_i
    end


    mem_total = mem_info['MemTotal'] / 1024
    mem_free = (mem_info['MemFree'] + mem_info['Buffers'] + mem_info['Cached']) / 1024
    mem_used = mem_total - mem_free
    mem_percent_used = (mem_used / mem_total.to_f * 100).to_i

    swap_total = mem_info['SwapTotal'] / 1024
    swap_free = mem_info['SwapFree'] / 1024
    swap_used = swap_total - swap_free
    unless swap_total == 0    
      swap_percent_used = (swap_used / swap_total.to_f * 100).to_i
    end

    report = {}

    report['Memory Total'] = mem_total
    report['Memory Used'] = mem_used
    report['% Memory Used'] = mem_percent_used

    report['Swap Total'] = swap_total
    report['Swap Used'] = swap_used
    unless  swap_total == 0   
      report['% Swap Used'] = swap_percent_used
    end

    { :report => report }
    
  rescue Exception => e
    body = if e.message =~ /No such file or directory/
      %Q(Unable to find /proc/meminfo. Please ensure your operationg system supports procfs:
         http://en.wikipedia.org/wiki/Procfs)
    else
      "An error occurred profiling the memory:\n\n#{e.message}\n\n#{e.backtrace}"
    end
    {:error => {:subject => "Unable to Profile Memory",
                :body    => body}}
  end
end
