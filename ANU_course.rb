require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'set'
 
class ANU_Course
	attr_reader :out_of_sync, :title, :is_draft, :concourse_ID, :code, :concourse_title
	attr_reader :is_draft, :to_finalise, :concourse_department

	def get_Concourse_summary(info)
		@concourse_title = info["Course Title"].to_s
		#puts "title: " + @concourse_title
		@concourse_ID = info["Course Identifier"].to_s.strip
		#puts "ID: " + @concourse_ID
		if @concourse_ID == ""
			return
		end
		@code = @concourse_ID[0..7]
		@prefix = @concourse_ID[0..3]
		@number = @concourse_ID[4..7]
		@concourse_from_template = $school_template[info["Linked To"]]
		#puts "linked to: #{@concourse_from_template or ''}"
		@concourse_session = info["Session"].to_s
		#puts "session: " + @concourse_session
		@concourse_year = info["Year"].to_s
		#puts "year: " + @concourse_year
		@concourse_campus = info["Campus"]
		#puts "campus : " + @concourse_campus
		@is_draft = ["DRAFT", "Unused_DRAFT", "Unused"].include? @concourse_campus 
		@concourse_college = "ANU "+info["School"]
		#puts "college: " + @concourse_college
		@concourse_department = $concourse_department_name[info["Department"]]
		#puts "dept: " + @concourse_department
		@concourse_credits = info["Credits"].to_s
		#puts "credits: " + @concourse_credits
		@concourse_delivery = info["Delivery Method"].to_s
		#puts "delivery: #{@concourse_delivery or ' '}"
		@concourse_instructor = info["Instructor"].to_s
		#puts "instructor: #{ @concourse_instructor or ' '}"
		@concourse_start = info["Start Date"]
		#puts "start: " + @concourse_start
		@concourse_end = info["End Date"]
		#puts "end: " + @concourse_end
		@concourse_last_modified = info["Syllabus Last Modified"]
		#puts "last: " + @concourse_last_modified
		@concourse_is_template = info["Template"]
		#puts "template: #{ @concourse_is_template or ' '}"
		if @concourse_is_template=="Yes" and @concourse_campus == "FINAL"
			puts "Error:" + @concourse_ID + " is in FINAL campus but it is a template"
		elsif @concourse_is_template != "Yes" and @concourse_campus != "FINAL"
			puts "Error:" + @concourse_ID + " is not a template and its in the #{@concourse_campus} campus"
		end
		@audit_status = info["Audit Status"]
		#puts "audit : " + @audit_status
		@audit_date = info["Audit Date"]
		#puts "audit date: " + @audit_date
		@out_of_sync = 0
	end

	def check_audit_status
		@to_finalise = 0
		if @concourse_campus == "DRAFT" and @audit_status =="Reviewed"
			#puts "campus : " + @concourse_campus
			newIDsuffix = "_"+$short_name[@concourse_session]+"_"+@concourse_year
			@final_ID = @concourse_ID.sub! "DRAFT", newIDsuffix	
			if $courselist.include? (@final_ID)
				puts @final_ID + "is already created"########## not working ############
				return
			else		
				audit_year = @audit_date[-2..-1].to_i
				#puts "audit year " + audit_year.to_s + " this year " + $time.year.to_s
				audit_month = @audit_date[-5..-4].to_i
				puts "audit month " + audit_month.to_s + " this month " + $time.month.to_s
				if audit_year == $time.year and audit_month >= ($time.month)-3
					@to_finalise = 1
				elsif $time.month <3 and audit_year.to_s == $time.year-1 and audit.month >10
					@to_finalise = 1
				else
					puts "hasn't been recently audited"
				end
			end
		end
		puts  "to finise? "+ @to_finalise.to_s
	end

	def change_to_final
		@concourse_from_template = @concourse_ID
		@concourse_ID = @final_ID
		@concourse_campus = "FINAL"
		#set start and end dates
		@concourse_start = "01/01/#{$sync_year}"
		@concourse_end = "12/31/#{$sync_year}"  
		@concourse_is_template = 0
	end

	def open_PandC
		#open the matching page in P&C
		url = "http://programsandcourses.anu.edu.au/"+$sync_year+"/course/"+@code
		encoded_url = URI.encode(url)
		@doc_PandC=Nokogiri::HTML(open(encoded_url))
		#puts "I'm in"
		#puts @doc_PandC

		# check Title
		@title = @doc_PandC.css('title').inner_html
		@title.slice!(" - ANU")
		if @title == "Page not found"
			return
		end
		if @title != @concourse_title
			# update Concourse to ensure titles match
			puts "#{@concourse_ID}: Syllabus feed will update title from #{@concourse_title} to #{@title}"
			@out_of_sync = 1
		end
	end

	def match_PandC_summary
		#extract the summary information from P&C into a summary and an array of the headings in the summary
		summary = Hash.new 
		summary_headings = Array.new
		search_summary_headings = @doc_PandC.css('span.degree-summary__code-heading')
		summary_length = search_summary_headings.length
		for i in 0..(summary_length-1)
			heading = ActionView::Base.full_sanitizer.sanitize(search_summary_headings[i].to_s)
			summary_headings[i]= heading
		end
		search_summary = @doc_PandC.css('div.degree-summary__codes').inner_html.to_s
		summary_lines = ActionView::Base.full_sanitizer.sanitize(search_summary)

		# check Offered in year and session
		@offered_in_sync_year = summary_headings.index("Offered in")
		if @offered_in_sync_year
			str1_marker = summary_headings[@offered_in_sync_year]
			str2_marker = summary_headings[@offered_in_sync_year+1]
			offering_info = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].split
			@in_year = offering_info[-1]
			if @in_year != $sync_year
				#if the year written in P&C doens't match the year in the url, complain
				puts "#{@concourse_ID}: Something wrong with the scheduling year in PandC"
			end
			if @in_year != @concourse_year
				# update year in Concourse so it matches P&C
				puts "#{@concourse_ID}: Syllabus feed will udate Year from #{@concourse_year} to #{@in_year}"
				@out_of_sync = 1
			end
			if offering_info.count($sync_year)>1
				# if offered more than once in the year, warn but don't update session
				$unsunc_file.write("#{@concourse_ID}, Offered more than once in #{$sync_year},"\
					" Update the Session in the Concourse Draft manually\n")
				@in_session = @concourse_session
			else	
				@in_session  = $session_name[offering_info[0]]
				if @in_session != @concourse_session
					# if offered only once in the year, update Concourse to the correct session
					puts "#{@concourse_ID} Syllabus feed will udpate Session from #{@concourse_session}"\
					" to #{@in_session}"
					@out_of_sync = 1
				end
			end
		else
			puts "Not offered in 2016, moving to Unused_DRAFT campus"
			@concourse_campus = "Unused_DRAFT"
		end

		#check College
		college_heading = summary_headings.index("ANU College")
		str1_marker = summary_headings[college_heading]
		str2_marker = summary_headings[college_heading+1]
		college = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].to_s
		if college.split.count("College") > 1
			# if offered by more than one College, warn but don't change anything
			$unsunc_file.write("#{@concourse_ID}, Offered by more than one College,"\
				" Syllabus feed will not change the College or Department in Concourse.\n")
			@college = @concourse_college
		else
			@college = college.strip
			if @college != @concourse_college
				# if College in P&C doens't match Concourse, update in Concourse
				puts "#{@concourse_ID}: Syllabus feed will update College from #{@concourse_college} to #{@college} "
				@out_of_sync = 1
			end
			# check Offered by department
			offer_heading = summary_headings.index("Offered by")
			str1_marker = summary_headings[offer_heading]
			str2_marker = summary_headings[offer_heading+1]
			dept = summary_lines[/#{str1_marker}(.*?)#{str2_marker}/m, 1].to_s
			@by_dept = $concourse_department_name[dept.strip]
			if @by_dept == nil
				#if can't determine Department from P&C, warn but don't change in Concourse
				$unsunc_file.write('#{@concourse_ID}, "Offered By" in P&C not recognised,'\
				" Syllabus feed will leave Department unchanged in Concourse\n")
				@by_dept = @concourse_department
			elsif @by_dept != @concourse_department
				#if Deparment in P&C doesn't match Concourse, update in Concourse
				puts "#{@concourse_ID}: Syllabus feed will update the offering Department from #{@concourse_department} to #{@by_dept}"
				@out_of_sync =1
				if @concourse_from_template != $school_template[dept.strip]
					$unsunc_file.write("#{@concourse_ID}, The Concourse draft is from the "\
						"#{@concourse_from_template} but it looks like it should be the "\
						"#{$school_template[dept.strip]},"\
						"This cannot be changed with Syllabus feed so you will need to sync manually. "\
						"Or delete the Draft outline and make a replacement.")
				end
			end
		end

		#check credits / unit value
		search_units = @doc_PandC.css('li.degree-summary__requirements-units')
		units_lines = ActionView::Base.full_sanitizer.sanitize(search_units.to_s)
		str1_marker = "Unit Value"
		str2_marker = "units"
		@unit_value = units_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip 
 		if @unit_value != @concourse_credits
 			# make unit value in Concourse match P&C
 			puts "#{@concourse_ID}: Syllabus feed will update the unit value from #{@concourse_credits}"\
 			" to #{@unit_value}"
 			@out_of_sync = 1
 		end

		# check mode of delivery
		delivery_on_PandC = summary_headings.index("Mode of delivery")
		if  delivery_on_PandC
			str1_marker = summary_headings[delivery_on_PandC]
			str2_marker = summary_headings[delivery_on_PandC+1]
			@in_mode = summary_lines[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			if @concourse_delivery == nil 
				#if Concourse doesn't list Delivery Mode add from P&C
				@concourse_delivery = @in_mode
			elsif @in_mode != @concourse_delivery 
				#if Concourse does list Delivery Mode, don't chagne it but warn if P&C doesn't match
	 			$unsunc_file.write("#{@concourse_ID}, P&C delivery mode (#{@in_mode}) does not match,"\
	 				" Syllabus file will not change Concourse mode (#{@concourse_delivery})\n")
			end
		end	

 		# check convener / instructor
		convener_on_PandC = summary_headings.index("Course convener")
		if convener_on_PandC
			str1_marker = summary_headings[convener_on_PandC]
			str2_marker = summary_headings[convener_on_PandC+1]
			@instructor = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			if @instructor == nil
				#if Concourse doesn't list Instructor add from P&C
				@concourse_instructor = @instructor
			elsif @instructor != @concourse_instructor
				#if Concourse does list Instructor, don't change it but warn if P&C doesn't match
	 			$unsunc_file.write("#{@concourse_ID}, P&C convener (#{@instructor}) does not match,"\
	 				" Syllabus file will not change Concourse instructor (#{@concourse_instructor})\n")
				@out_of_sync = 1
			end
		end
 	end

	def write_course_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@concourse_ID or 'error'}|")
		#write TITLE|
		file.write("#{@title or 'error'}|")
		#write CAMPUS_IDENTIFIER|
		file.write("#{@concourse_campus or 'error'}|")
		#write DEPARTMENT_IDENTIFIER|
		file.write("#{@by_dept or 'error'}|")   
		#write START_DATE|
		file.write("01/01/#{$sync_year}|")   
		#write END_DATE|
		file.write("31/12/#{$sync_year}|")   
		#write CLONE_FROM_IDENTIFIER|
		file.write("#{@concourse_from_template or 'Other'}|")   
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
		file.write("#{@concourse_is_template}|")
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

	def get_PandC_description_LOs
		#find the course description
		@description = @doc_PandC.css('div.introduction').inner_html.strip
		#puts "Description: " + @description

		search = @doc_PandC.css('div.body__inner').inner_html

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
		file.write("#{@concourse_ID or 'error'}_Draft|")
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
		file.write("#{@concourse_ID or 'error'}_Draft|")
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

