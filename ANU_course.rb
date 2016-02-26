require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'set'
# see help with cleaning here http://kevinquillen.com/programming/2014/06/23/ruby-gets-shit-done
# 

	# get all its P&C properties
# 

class ANU_Course
#	@@num_courses = Set.new
	attr_accessor :offering_name

	def get_Concourse_summary(info)
		@concourse_title = info[0]
		@concourse_ID = info[1]

		@prefix = @concourse_ID[0..3]
		@number = @concourse_ID[4..7]
		if @concourse_ID != @prefix+@number+"_Draft"
			puts "Note" + @concourse_ID+ " is not a standard format course ID."
		end
		@concourse_from_template = $school_template[info[4]]
		@concourse_session = info[7].to_s
		@concourse_year = info[8].to_s
		@concourse_campus = info[9]
		@concourse_college = "ANU "+info[10]
		@concourse_department = $concourse_department_name[info[11]]
		@concourse_credits = info[12].to_s
		@concourse_delivery = info[13].to_s
		@concourse_instructor = info[14].to_s

		@out_of_sync = 0
	end

	def get_PandC_summary(doc)


		#find the summary information
		summary = Hash.new 
		summary_headings = Array.new
		search_summary_headings = doc.css('span.degree-summary__code-heading')
		summary_length = search_summary_headings.length
		for i in 0..(summary_length-1)
			heading = ActionView::Base.full_sanitizer.sanitize(search_summary_headings[i].to_s)
			summary_headings[i]= heading

		end
		search_summary = doc.css('div.degree-summary__codes').inner_html.to_s
		summary_lines = ActionView::Base.full_sanitizer.sanitize(search_summary)
		puts search_summary
		$testoutputfile.write(@concourse_ID)
		$testoutputfile.write(summary_headings)
		$testoutputfile.write(summary_lines)


		# find the course title
		#puts doc
		search_title = doc.css('span.intro__degree-title__component').inner_html
		@title = ActionView::Base.full_sanitizer.sanitize(search_title.to_s)
		if @title != @concourse_title
			puts "#{@concourse_ID}: Syllabus feed will update title from #{@concourse_title} to #{@title}"
			@out_of_sync = 1
		end



		@offered_in_sync_year = summary_headings.index("Offered in")
		if @offered_in_sync_year
			str1_marker = summary_headings[@offered_in_sync_year]
			str2_marker = summary_headings[@offered_in_sync_year+1]
			offering_info = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].split
			@in_year = offering_info[-1]
			if @in_year != $sync_year
				puts "#{@concourse_ID}: Something wrong with the scheduling year in PandC"
			end
			if @in_year != @concourse_year
				puts "#{@concourse_ID}: Syllabus feed will udate Year from #{@concourse_year} to #{@in_year}"
				@out_of_sync = 1
			end
			if offering_info.count($sync_year)>1
				puts "#{@concourse_ID} is offered more than once in #{$sync_year} - please update the Session in the Concourse Draft manually"
				@in_session = @concourse_session
			else	
				@in_session  = $session_name[offering_info[0]]
				if @in_session != @concourse_session
					puts "#{@concourse_ID}: Syllabus feed will udpate Session from #{@concourse_session} to #{@session}}"
					@out_of_sync = 1
				end
			end
		end

		str1_marker = "Offered by"
		str2_marker = "ANU College"
		dept = summary_lines[/#{str1_marker}(.*?)#{str2_marker}/m, 1].to_s
		@by_dept = $concourse_department_name[dept.strip]
		if @by_dept == nil
			$unsunc_file.write("#{@concourse_ID}: Offered By department in P&C not recognised - can't update in Concourse")
			@by_dept = @concourse_department
		elsif @by_dept != @concourse_department
			puts "#{@concourse_ID}: Syllabus feed will update the offering Department from #{@concourse_department} to #{@by_dept}"
			@out_of_sync =1
			@from_template = $school_template[dept.strip]
			if @from_template != @concourse_from_template
				puts "#{@concourse_ID}: The Concourse draft is from the #{@concourse_from_template} but it looks like it should be the #{@from_template}. 
				       This cannot be changed with Syllabus feed so you will need to sync manually."
			end
		end


		str1_marker = "ANU College</span>"
		str2_marker = "Offered in"
		college = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		puts "This is the start of the College string::::"+college+":::and this is the end"
		puts college.spilt
		if college.split.count["College"]>1
			$unsunc_file.write("#{@concourse_ID} is offered by more than one College. Sync will not change the College in Concourse.")
			@college = @concourse_college
		elsif 
			@college = college.strip
			@college != @concourse_college
			puts "#{@concourse_ID}: Syllabus feed will update College from #{@concourse_college} to #{@college} "
			@out_of_sync = 1
		end

		delivery_on_PandC = summary_headings.index("Mode of delivery")
		if  delivery_on_PandC
			str1_marker = summary_headings[delivery_on_PandC]
			str2_marker = summary_headings[delivery_on_PandC+1]
			@in_mode = summary_lines[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			if @in_mode != @concourse_delivery
	 			$unsunc_file.write("#{@concourse_ID}: P&C delivery mode (#{@in_mode}) does not match Concourse (#{@concourse_delivery})\n")
			end
		end	

		search_units = doc.css('li.degree-summary__requirements-units')
		units_lines = ActionView::Base.full_sanitizer.sanitize(search_units.to_s)
		str1_marker = "Unit Value"
		str2_marker = "units"
		@unit_value = units_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip 
 		if @unit_value != @concourse_credits
 			puts "#{@concourse_ID}: Syllabus feed will update the unit value from #{@concourse_credits} to #{@unit_value}"
 			@out_of_sync = 1
 		end

		convener_on_PandC = summary_headings.index("Course convener")
		if convener_on_PandC
			str1_marker = summary_headings[convener_on_PandC]
			str2_marker = summary_headings[convener_on_PandC+1]
			@instructor = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			if @instructor != @concourse_instructor
	 			$unsunc_file.write("#{@concourse_ID}: P&C convener (#{@instructor}) does not match Concourse (#{@concourse_instructor})\n")
				@out_of_sync = 1
			end
		end
 	end

	def write_course_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@Concourse_ID or 'error'}_Draft|")
		#write TITLE|
		file.write("#{@title or 'error'}|")
		#write CAMPUS_IDENTIFIER|
		file.write("DRAFT|")
		#write DEPARTMENT_IDENTIFIER|
		file.write("#{@by_dept or 'error'}|")   
		#write START_DATE|
		file.write("01/01/#{$sync_year or '2000'}|")   
		#write END_DATE|
		file.write("12/31/2100|")   
		#write CLONE_FROM_IDENTIFIER|
		file.write("#{@from_template or 'Other'}|")   
		#write TIMEZONE|
		file.write("Australia/Sydney|")
		#write PREFIX|
		file.write("#{@prefix or ''}|") 
		#write NUMBER|
		file.write("#{@number or ''}|") 
		#write INSTRUCTOR|
		file.write("#{@concourse_instructor or ''}|")   
		#write SESSION|
		file.write("#{@in_session or ''}|")   
		#write YEAR|
		file.write("#{@in_year or ''}|")   
		#write CREDITS|
		file.write("#{@unit_value or ''}|")
		#write DELIVERY_METHOD|
		file.write("#{@concourse_delivery or ''}|")
		#write IS_STRUCTURED|
		file.write("1|")
		#write IS_TEMPLATE|
		file.write("1|")
		#write HIDDEN_FROM_SEARCH
		file.write("0\n")
		#puts "Finished writing #{@prefix}#{@number} to the course feed file"
	end

	def write_section_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@Concourse_ID or 'error'}_Draft|")
		#write SECTION_IDENTIFIER|
 		file.write("#{@prefix or 'error'}#{@number or 'error'}_Draft_Draft|")
 		#write SECTION_LABEL
		file.write("Draft\n")
		#puts "Finished writing #{@prefix}#{@number} to the section feed file"
	end

	def get_PandC_description_LOs(doc)
		#find the course description
		@description = doc.css('div.introduction').inner_html.strip
		#puts "Description: " + @description

		search = doc.css('div.body__inner').inner_html

		#find the Requisites and Incompatibilbity notices
		str1_marker = "Incompatibility</h2>"
		str2_marker = "<h2"
		search_requisite = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		if search_requisite
			@requisite = ActionView::Base.full_sanitizer.sanitize(search_requisite.to_s.strip).strip
			#puts "Requisites and incompatibility: " + @requisite 
		end

		#find the other notices (to go into Description Notes)
		str1_marker = "Other Information</h2>"
		str2_marker = "<h2"
		search_other = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		if search_other
			str1_marker = ""
			str2_marker = " <!-- START SUB-PLANS -->"
			@other = search_other.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			#other = ActionView::Base.full_sanitizer.sanitize(search_other.to_s).strip
			#puts "Other Information: #{@other or 'unknown'}"
		end

		# find the LO's
		str1_marker = "Learning Outcomes</h2>"
		str2_marker = '<h2 id="indicative-assessment">'
		search_LOs = search.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		if search_LOs
			@learningOutcomes = search_LOs.strip
			#puts "Learning Outcomes: " 
			#puts @learningOutcomes
		end
	end

	def write_description_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@Concourse_ID or 'error'}_Draft|")
		#write DESCRIPTION|
		file.write("#{@description or ''}|")
		#write REQUISITES|
		file.write("#{@requisite or ''}|")
		#write NOTES|
		file.write("#{@other or ''}|")
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#IS_LOCKED
		file.write("1\n")
		#puts "Finished writing #{@prefix}#{@number} to the description feed file"
	end

	def write_LO_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@Concourse_ID or 'error'}_Draft|")
		#write OUTCOMES|
		file.write("#{@learningOutcomes or ''}|")
		#write NOTES|
		file.write("|")
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#write IS_LOCKED
		file.write("1\n")
		#puts "Finished writing #{@prefix}#{@number} to the learning outcomes feed file"
	end

end

