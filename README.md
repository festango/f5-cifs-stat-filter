F5 CIFS WORKER STAT FORMATTER
=========================

Script to parse and format flat stat output into human readable CSV format.

<q>
 Ussage:

   $ stat_cifs_work_all.rb <terminal_log_file>

   => Example output in CSV format 
   2012-07-05 02:24:23, 16, 58, 8, 0, 0, 3, 4, 0, 1, 0,43, 10, 20, 0, 0, 23
   2012-07-05 02:24:28, 16, 88, 3, 0, 0, 2, 1, 0, 0, 0,18, 67, 55, 0, 0, 63
   2012-07-05 02:24:31, 16, 29, 13, 0, 0, 1, 2, 0, 0, 0,8, 2, 34, 0, 0, 74 

 Expected Input:
   vcifs work queues dumped at 2012-07-05 02:24:31 UTC

   main worklist:
   | 59 items, high 267, at 2012-07-05 02:21:11
   | ready list:
   | | ctx 6.16 CLIENT_REQ TRANSACTION2/QUERY_FILE_INFORMATION 21 msec
   | 43 entries
   | active list:
   | | ctx 5.12 CLIENT_REQ TRANSACTION2/FIND_FIRST2 on tid 4508, 1 msec, filer wait
   | 16 entries
   | 16 work threads, 0 idle, 16 threads max
   | 174449 items served
   | 0 items discarded
   | alert clear, threshold 8
</q>
