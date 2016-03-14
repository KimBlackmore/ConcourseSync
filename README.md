# ConcourseSync
An app to keep [ANU Concourse](https://anu.campusconcourse.com/search?keyword=&search_performed=1) up to date with to [Programs and Courses](http://programsandcourses.anu.edu.au/)

The syncing software has three main programs

* concourse_add_drafts.rb
* concourse_sync.rb
* concourse_finalise.rb

They take input files which are csv files saved in the Input directory under the main files, and output feed files ready for uploading to Concourse

**concourse_add_drafts.rb**

<em> Input </em>
  * P&C_courselist.csv - a screen grab of course codes and titles from a search of P&C for all courses or for one College
  * Concourse_Syllabus_report-all.com - a syllabus report from Concourse for ALL courses
  
<em> Output </em>

  * course_feed.csv
  * Section_feed.csv
  * description_feed.csv
  * LOs_feed.csv
  * unsunc.csv (a list of exceptions that need to be handled manually)
  
**concourse_sync.rb**

<em> Input </em>
  * Concourse_Syllabus_report-all.com - a syllabus report from Concourse for ALL courses
  
<em> Output </em>

  * course_feed.csv
  * description_feed.csv
  * LOs_feed.csv
  * unsunc.csv (a list of exceptions that need to be handled manually)
  
**concourse_finalise.rb**

<em> Input </em>
  * Concourse_Syllabus_report_to_final.com - syllabus report from Concourse for the classes you want to finalise, usually Draft outlines for a particular year and session, and a particular Department
  
<em> Output </em>

  * course_feed.csv
  * Section_feed.csv
  * unsunc.csv (a list of exceptions that need to be handled manually)
