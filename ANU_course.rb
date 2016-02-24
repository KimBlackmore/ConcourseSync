

# see help with cleaning here http://kevinquillen.com/programming/2014/06/23/ruby-gets-shit-done
# 

	# get all its P&C properties
	# check if they match the Concourse properties
	# if not warn 
	# 	- including if course is not in Concourse at all
	# 	- or is in unused_drafts
	# and add lines feed files to fix it
# 

class ANU_Course
	@@no_of_courses = 0

	def set_code(p,n)
		@prefix = p
		@number = n
	end

	def get_PandC
		pandc_url = "http://programsandcourses.anu.edu.au/2016/course/"+@prefix+@number
		doc=Nokogiri::HTML(open(pandc_url))

		# find the course title
		search_title = doc.css('span.intro__degree-title__component').inner_html
		@title = ActionView::Base.full_sanitizer.sanitize(search_title.to_s)
		puts
		puts "Title:" + @title

		#find the course description
		@description = doc.css('div.introduction').inner_html
		puts "Description: " + @description

		search = doc.css('div.body__inner').inner_html

		#find the Requisites and Incompatibilbity notices
		str1_marker = "Incompatibility</h2>"
		str2_marker = "<h2"
		search_requisite = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
		@requisite = ActionView::Base.full_sanitizer.sanitize(search_requisite.to_s)
		puts "Requisites and incompatibility: " + @requisite 

		#find the other notices (to go into Description Notes)
		str1_marker = "Other Information</h2>"
		str2_marker = "<h2"
		search_other = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
		str1_marker = ""
		str2_marker = " <!-- START SUB-PLANS -->"
		@other = search_other.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
		#other = ActionView::Base.full_sanitizer.sanitize(search_other.to_s).strip
		puts "Other Information: #{@other or 'unknown'}"

		#find the Learning Outcomes
		str1_marker = "Learning Outcomes</h2>"
		str2_marker = '<h2 id="indicative-assessment">'
		@search_LOs = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
		puts "Learning Outcomes: " 
		puts @search_LOs

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
		@college = summary["ANU College"]
		puts "ANU College: #{@college or "unknown"}"
		@instructor = summary["Course convener"]
		puts "Course Convener: #{@instructor or 'unknown'}"

		offering_name = summary["Offered in"]
		@in_session  = $session_name[offering_name.split.first]
		puts "Session: #{@in_session or 'unknown'}" 
		@in_year = offering_name.split.last
		puts "Year: #{@in_year or 'unknown'}"
		@by_dept = $concourse_department[summary["Offered by"]]
		puts "Offered by: #{summary["Offered by"] or 'unknonwn'} which is #{@by_dept or '?'}"
		@from_template = $school_template[summary["Offered by"]]
		puts " and uses the #{@from_template or '?'} template"
		@in_mode = summary["Mode of Delivery"]
		puts "Mode of Delivery: #{@in_mode or 'unknown'}"

		search_units = doc.css('li.degree-summary__requirements-units')
		units_lines = ActionView::Base.full_sanitizer.sanitize(search_units.to_s)
		str1_marker = "Unit Value"
		str2_marker = "units"
		@unit_value = units_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip 
		puts "Units: " + @unit_value
	end

	def write_course_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft|")
		#write TITLE|
		file.write("#{@title or 'error'}|")
		#write CAMPUS_IDENTIFIER|
		file.write("Draft|")
		#write DEPARTMENT_IDENTIFIER|
		file.write("#{@by_dept or 'error'}|")   
		#write START_DATE|
		file.write("01/01/#{@in_year or '2000'}|")   
		#write END_DATE|
		file.write("12/31/2100|")   
		#write CLONE_FROM_IDENTIFIER|
		file.write("#{@from_template or 'Other'}|")   
		#write TIMEZONE|
		file.write("Australian/Sydney|")
		#write PREFIX|
		file.write("#{@prefix or ''}|") 
		#write NUMBER|
		file.write("#{@number or ''}|") 
		#write INSTRUCTOR|
		file.write("#{@instructor or ''}|")   
		#write SESSION|
		file.write("#{@in_session or ''}|")   
		#write YEAR|
		file.write("#{@in_year or ''}|")   
		#write CREDITS|
		file.write("#{@unit_value or ''}|")
		#write DELIVERY_METHOD|
		file.write("#{@in_mode or ''}|")
		#write IS_STRUCTURED|
		file.write("1|")
		#write IS_TEMPLATE|
		file.write("1|")
		#write HIDDEN_FROM_SEARCH
		file.write("0\n")
		puts "Finished writing #{@prefix}#{@number} to the course feed file"
	end

	def write_description_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft|")
		#write DESCRIPTION|
		file.write("#{@description or ''}|")
		#write REQUISITES|
		file.write("#{@requisite or ''}|")
		#write NOTES|
		file.write("#{@other or ''}|")
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#IS_LOCKED
		file.write("1")
		puts "Finished writing #{@prefix}#{@number} to the description feed file"
	end

	def write_section_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft|")
		#write SECTION_IDENTIFIER|
 		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft_Draft|")
 		#write SECTION_LABEL
		file.write("Draft")
		puts "Finished writing #{@prefix}#{@number} to the section feed file"
	end

	def write_LO_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft|")
		#write OUTCOMES|
		file.write("#{@search_LOs or ''}|")
		#write NOTES|
		file.write("|")
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#write IS_LOCKED
		file.write("1")
		puts "Finished writing #{@prefix}#{@number} to the learning outcomes feed file"

	end

end

