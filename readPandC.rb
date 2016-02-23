require 'nokogiri'
require 'open-uri'
require 'action_view'
# see help with cleaning here http://kevinquillen.com/programming/2014/06/23/ruby-gets-shit-done
# 
# setup useful hashes to use later:
session_name = {
	"First"=> "Semester 1", 
	"Second" => "Semester 2",
	"Summer" => "Summer",
	"Autumn" => "Autumn",
	"Winter" => "Winter",
	"Spring" => "Spring" }
concourse_department = {
	"ANU College of Asia and the Pacific" => "CHL",
	"ANU National Security College" => "Crawford",
	"Asia-Pacific College of Diplomacy" => "Bell",
	"Australian Centre on China in the World" => "CIW",
	"Coral Bell School of Asia Pacific Affairs" => "Bell",
	"Crawford School of Public Policy" => "Crawford",
	"Department of International Relations" => "Bell",
	"Department of Political and Social Change" => "Bell",
	"International and Development Economics Program" => "Crawford",
	"Policy and Governance Program" => "Crawford",
	"Regulatory Institutions Network Program" => "RJD",
	"Research School of Management" => "RSM",
	"School of Culture History and Language" => "CHL",
	"Strategic and Defence Studies Centre" => "Bell"
}
school_template = {
	"ANU College of Asia and the Pacific" => "CHL_Template",
	"ANU National Security College" => "NSC_Template",
	"Asia-Pacific College of Diplomacy" => "Bell_Template",
	"Australian Centre on China in the World" => "CIW_Template",
	"Coral Bell School of Asia Pacific Affairs" => "Bell_Template",
	"Crawford School of Public Policy" => "Crawford_Template",
	"Department of International Relations" => "Bell_Template",
	"Department of Political and Social Change" => "Bell_Template",
	"International and Development Economics Program" => "Crawford_Template",
	"Policy and Governance Program" => "Crawford_Template",
	"Regulatory Institutions Network Program" => "RJD_Template",
	"Research School of Management" => "RSM_Template",
	"School of Culture History and Language" => "CHL_Template",
	"Strategic and Defence Studies Centre" => "Bell_Template"
}
#
# 

prefix = "ASIA"
number = "2107"

pandc_url = "http://programsandcourses.anu.edu.au/2016/course/"+prefix+number

doc=Nokogiri::HTML(open(pandc_url))

# find the course title
search_title = doc.css('span.intro__degree-title__component').inner_html
title = ActionView::Base.full_sanitizer.sanitize(search_title.to_s)
puts
puts "Title:" + title

#find the course description
description = doc.css('div.introduction').inner_html
puts "Description: " + description

search = doc.css('div.body__inner').inner_html

#find the Requisites and Incompatibilbity notices
str1_marker = "Incompatibility</h2>"
str2_marker = "<h2"
search_requisite = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
requisite = ActionView::Base.full_sanitizer.sanitize(search_requisite.to_s)
puts "Requisites and incompatibility: " + requisite 

#find the other notices (to go into Description Notes)
str1_marker = "Other Information</h2>"
str2_marker = "<h2"
search_other = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
str1_marker = ""
str2_marker = " <!-- START SUB-PLANS -->"
other = search_other.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
#other = ActionView::Base.full_sanitizer.sanitize(search_other.to_s).strip
puts "Other Information: #{other or 'unknown'}"

#find the Learning Outcomes
str1_marker = "Learning Outcomes</h2>"
str2_marker = '<h2 id="indicative-assessment">'
search_LOs = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
puts "Learning Outcomes: " 
puts search_LOs

#find the summary information
summary = Hash.new 
search_summary_headings = doc.css('span.degree-summary__code-heading')
search_summary_text = doc.css('span.degree-summary__code-text')
summary_length = search_summary_headings.length
for i in 0..(summary_length-1)
	heading = ActionView::Base.full_sanitizer.sanitize(search_summary_headings[i].to_s)
	text = (ActionView::Base.full_sanitizer.sanitize(search_summary_text[i].to_s)).strip
	summary[heading] = text
end
puts "ANU College: #{summary["ANU College"] or "unknown"}"
instructor = summary["Course convener"]
puts "Course Convener: #{instructor or 'unknown'}"

offering_name = summary["Offered in"]
in_session  = session_name[offering_name.split.first]
puts "Session: #{in_session or 'unknown'}" 
in_year = offering_name.split.last
puts "Year: #{in_year or 'unknown'}"
by_dept = concourse_department[summary["Offered by"]]
puts "Offered by: #{summary['Offered by'] or 'unknonwn'} which is #{by_dept or '?'}"
from_template = school_template[summary["Offered by"]]
puts " and uses the #{from_template or '?'} template"
in_mode = summary["Mode of Delivery"]
puts "Mode of Delivery: #{in_mode or 'unknown'}"

search_units = doc.css('li.degree-summary__requirements-units')
units_lines = ActionView::Base.full_sanitizer.sanitize(search_units.to_s)
str1_marker = "Unit Value"
str2_marker = "units"
unit_value = units_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip 
puts "Units: " + unit_value

time = Time.new
timestamp = time.strftime("_%Y-%m-%d")
# these are indented because it's all about writing the course_feed_file
	course_feed_filename = "output/PandC_course_feed"+timestamp
	puts "I'm going to overwrite #{course_feed_filename or 'error!'}"
	puts "If you don't want that, hit CTRL-C (^C)."
	puts "If you do want that, hit RETURN."

	$stdin.gets

	puts "OK here goes..."

	course_feed_file = open(course_feed_filename,'w')
	course_feed_file.truncate(0)

	course_feed_file.write("COURSE_IDENTIFIER|TITLE|CAMPUS_IDENTIFIER|DEPARTMENT_IDENTIFIER|START_DATE|END_DATE|CLONE_FROM_IDENTIFIER|TIMEZONE|PREFIX|NUMBER|INSTRUCTOR|SESSION|YEAR|CREDITS|DELIVERY_METHOD|IS_STRUCTURED|IS_TEMPLATE|HIDDEN_FROM_SEARCH
	\n")
	#write COURSE_IDENTIFIER|
	course_feed_file.write("#{prefix or 'error'}#{number or 'error'}_Draft|")
	#write TITLE|
	course_feed_file.write("#{title or 'error'}|")
	#write CAMPUS_IDENTIFIER|
	course_feed_file.write("Draft|")
	#write DEPARTMENT_IDENTIFIER|
	course_feed_file.write("#{by_dept or ''}|")   
	#write START_DATE|
	course_feed_file.write("01/01/#{in_year or '2000'}|")   
	#write END_DATE|
	course_feed_file.write("31/12/#{in_year or '2100'}|")   
	#write CLONE_FROM_IDENTIFIER|
	course_feed_file.write("#{from_template or 'Other'}|")   
	#write TIMEZONE|
	course_feed_file.write("Australian/Sydney|")
	#write PREFIX|
	course_feed_file.write("#{prefix or ''}|") 
	#write NUMBER|
	course_feed_file.write("#{number or ''}|") 
	#write INSTRUCTOR|
	course_feed_file.write("#{instructor or ''}|")   
	#write SESSION|
	course_feed_file.write("#{in_session or ''}|")   
	#write YEAR|
	course_feed_file.write("#{in_year or ''}|")   
	#write CREDITS|
	course_feed_file.write("#{unit_value or ''}|")
	#write DELIVERY_METHOD|
	course_feed_file.write("#{in_mode or ''}|")
	#write IS_STRUCTURED|
	course_feed_file.write("1|")
	#write IS_TEMPLATE|
	course_feed_file.write("1|")
	#write HIDDEN_FROM_SEARCH
	course_feed_file.write("0|\n")
	puts "... all done."

#next write the description feed file
#
#and finally the learning outcomes feed file


