#!/usr/bin/env ruby
#
# Written by Shunsuke Takahashi (s.takahashi at f5.com)
# All Rights Reserved.
#
# Ussage:
#
#   $ stat_cifs_work_all.rb <terminal_log_file>
#
#   => Output will be in CSV format 
#   2012-07-05 02:24:23, 16, 58, 8, 0, 0, 3, 4, 0, 1, 0,43, 10, 20, 0, 0, 23
#   2012-07-05 02:24:28, 16, 88, 3, 0, 0, 2, 1, 0, 0, 0,18, 67, 55, 0, 0, 63
#   2012-07-05 02:24:31, 16, 29, 13, 0, 0, 1, 2, 0, 0, 0,8, 2, 34, 0, 0, 74 
#
# Expected Log Message:
#   vcifs work queues dumped at 2012-07-05 02:24:31 UTC
#
#   main worklist:
#   | 59 items, high 267, at 2012-07-05 02:21:11
#   | ready list:
#   | | ctx 6.16 CLIENT_REQ TRANSACTION2/QUERY_FILE_INFORMATION 21 msec
#   | 43 entries
#   | active list:
#   | | ctx 5.12 CLIENT_REQ TRANSACTION2/FIND_FIRST2 on tid 4508, 1 msec, filer wait
#   | 16 entries
#   | 16 work threads, 0 idle, 16 threads max
#   | 174449 items served
#   | 0 items discarded
#   | alert clear, threshold 8
#
class Job
  def initialize
    @time_stamp = ""    # Timestamp
    @ready_count  = 0 
    @active_count = 0
    @ready_jobs   = {"TRANSACTION2/FIND_FIRST2"=>0,
                     "TRANSACTION2/QUERY_FS_INFORMATIO"=>0,
                     "TRANSACTION2/QUERY_PATH_INFORMATION"=>0,
                     "OTHER"=>0}
    @active_jobs  = {"TRANSACTION2/FIND_FIRST2"=>0,
                     "TRANSACTION2/QUERY_FS_INFORMATIO"=>0,
                     "TRANSACTION2/QUERY_PATH_INFORMATION"=>0,
                     "OTHER"=>0}
    @ready_items  = []
    @active_items = []
  end
  attr_accessor :time_stamp, :ready_count, :active_count
  attr_reader :ready_jobs, :active_jobs

  def add_ready(l)
    #| | ctx 7.12 CLIENT_REQ TRANSACTION2/FIND_FIRST2 181 msec
    values = l.split("\s")
    item = Hash.new
    item[:type] = values[4] # CLIENT_REQ
    item[:smb] = values[5]  # TRANSACTION2/FIND_FIRST2
    item[:avg] = values[6]  # 181

    # SMB command level counter
    if @ready_jobs[item[:smb]]
      @ready_jobs[item[:smb]] += 1 
    else
      @ready_jobs["OTHER"] += 1
    end
    @ready_items.push(item)
 
    return true
 end

  def add_active(l)
    #| | ctx 7.12 CLIENT_REQ TRANSACTION2/FIND_FIRST2 on tid 9727, 18987 msec, filer wait
    values = l.split("\s")
    item = Hash.new
    item[:type] = values[4]     # => CLIENT_REQ
    item[:smb] = values[5]      # => TRANSACTION2/FIND_FIRST2
    item[:tid] = values[8]      # => 9727
    item[:avg] = values[9]      # => 181987
    item[:reason] = values[10]  # => filer wait
    @active_items.push(item)
    
    # SMB command level counter
    if @active_jobs[item[:smb]]
      @active_jobs[item[:smb]] += 1 
    else
      @active_jobs["OTHER"] += 1
    end
    @active_items.push(item)
  
    return true
  end

  def avg(type)
    # To support both list in one methods
    type == :active ? i = @active_items : i = @ready_items

    # Sum up all the average time within one job
    ttl = 0 
    i.each {|item| ttl += item[:avg].to_i}
   
    # Calculate Average Time in the list
    unless i.size == nil || i.size == 0
      avg = ttl / i.size
    else
      avg =  0
    end
    return avg
  end
end


# Main Procedure
FILE = ARGF.filename
MN_DELIMITER = "vcifs work queues dumped "

# Load Log File line by line and calcuate statitsitcs information.
res = []
i = 0
f = File.new(FILE)
f.each do |l|
# Start new job when script found the command input
  if l.index(MN_DELIMITER)
    i = 0
    a = 0
    res.push(Job.new)
  end

  # Swich process based on the string 
  case l
  when /^vcifs work queues dumped at/
    # Regex to match with "2012-06-12 12:35:32"
    res[-1].time_stamp = l.scan(/\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d/)[0]
  when /^\| ready list:/
    i = :ready_count
  when /^\| active list:/
    i = :active_count
  else # Add to the job
    if i==:ready_count && l.index("| | ctx ")
      res[-1].ready_count += 1  
      res[-1].add_ready(l)
    elsif i==:active_count && l.index("| | ctx ")
      res[-1].active_count += 1 
      res[-1].add_active(l)
    else
      next
    end 
  end # of case
end # if f.each

# Generate CSV
puts "Time,#Active List, #Active(Avg),TRANSACTION2/FIND_FIRST2, TRANSACTION2/QUERY_FS_INFORMATIO, TRANSACTION2/QUERY_PATH_INFORMATION,TRANSACTION2/QUERY_FILE_INFORMATION,NT_CREATE_ANDX, NT_CANCEL, CLOSE, Other, #Ready List, Ready(Avg), TRANSACTION2/FIND_FIRST2, TRANSACTION2/QUERY_FS_INFORMATIO, TRANSACTION2/QUERY_PATH_INFORMATION, Other"

res.each { |job| puts "#{job.time_stamp}, #{job.active_count}, #{job.avg(:active)}, #{job.active_jobs.values.join(", ")},#{job.ready_count}, #{job.avg(:ready)}, #{job.ready_jobs.values.join(", ")}" }

