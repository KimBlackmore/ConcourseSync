require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'set'
 
class ANU_Course
	attr_reader :out_of_sync, :title, :is_draft, :concourse_ID, :code, :concourse_title
	attr_reader :is_draft, :to_finalise, :concourse_department

	def initialize(name)
		@concourse_ID = name
		@out_of_sync = 0
	end

	def get_Concourse_summary(info)
		@concourse_title = info["Course Title"].to_s
		#puts "title: " + @concourse_title
		@concourse_from_template = $school_template[info["Linked To"]]
		#puts "#{@concourse_ID} linked to: #{@concourse_from_template or 'error'}"
		@concourse_session = info["Session"].to_s
		#puts "session: " + @concourse_session
		@concourse_year = info["Year"].to_s
		#puts "year: " + @concourse_year
		@concourse_campus = info["Campus"]
		#puts @concourse_ID + " campus : " + @concourse_campus
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
		@concourse_last_modified = info["Syllabus Last Modified"]
		#puts "last: " + @concourse_last_modified
		@concourse_is_template = info["Template"]
		#puts "template: #{ @concourse_is_template or ' '}"
		if @concourse_is_template=="Yes" and @concourse_campus == "FINAL"
			puts "Error: " + @concourse_ID + " is in FINAL campus but it is a template"
		elsif @concourse_is_template != "Yes" and @concourse_campus != "FINAL"
			puts "Error: " + @concourse_ID + " is not a template and its in the #{@concourse_campus} campus"
		end
		if @concourse_is_template=="Yes" and !@concourse_from_template
			puts "Error: #{@concourse_ID } says its a template but isn't linked to one above"
		elsif @concourse_is_template != "Yes" and @concourse_from_template != nil
			puts "Error: #{@concourse_ID } says its not a template but it is lined to #{@concourse_from_template}"			
		end

		@audit_status = info["Audit Status"]
		#puts "audit : " + @audit_status
		@audit_date = info["Audit Date"]
		#puts "audit date: " + @audit_date
	end

	def create_empty(info)
		@concourse_title = info["TITLE"].to_s
		@concourse_from_template = ""
		@concourse_session = ""
		@concourse_year = ""
		@concourse_campus = "DRAFT"		
		@concourse_college = ""
		@concourse_department = ""
		@concourse_credits = ""
		@concourse_delivery = "" 
		@concourse_instructor = ""
		@concourse_last_modified = ""
		@concourse_is_template = ""
	end

	def check_audit_status
		@to_finalise = 0
		if @concourse_campus == "DRAFT" and @audit_status =="Reviewed"
			newIDsuffix = $short_name[@concourse_session]+"_"+@concourse_year
			@final_ID = @concourse_ID.gsub("Draft", newIDsuffix)
			if $courselist.include? (@final_ID)
				#puts @final_ID + " is already created"
				return
			else		
				audit_year = 2000+ @audit_date[-2..-1].to_i
				#puts "audit year " + audit_year.to_s + " this year " + $time.year.to_s
				audit_month = @audit_date[-5..-4].to_i
				#puts "audit month " + audit_month.to_s + " this month " + $time.month.to_s
				if audit_year == $time.year and audit_month >= ($time.month)-3
					@to_finalise = 1
					#puts "finalise #{@concourse_ID} to #{@final_ID}"
				elsif $time.month <3 and audit_year.to_s == $time.year-1 and audit.month >10
					@to_finalise = 1
					#puts "finalise #{@concourse_ID} to #{@final_ID}"
				else
					#puts "#{@concourse_ID} has not final version and hasn't been recently audited"
				end
			end
		end 
	end

	def make_final
		@title = @concourse_title
		@in_session = @concourse_session
		@in_year = @concourse_year
		@by_dept = @concourse_department
		@unit_value = @concourse_credits
	end


	def retire
		if @concourse_title.include?(" Not in P&C")
			@title = @concourse_title
		else
			@title = @concourse_title + " - Not in P&C"
			puts "#{@concourse_ID}: Not on P&C for #{$sync_year} - adding this to title"
			@out_of_sync += 1
		end
		@by_dept = @concourse_department
		@in_year = ""
		@in_session = ""
		@unit_value = @concourse_credits
		if @concourse_campus == "DRAFT"
			@concourse_campus = "Unused_DRAFT"			
			puts "#{@concourse_ID}, Not on P&C for #{$sync_year}, moving to Unused DRAFT campus"
			@out_of_sync += 1
		end
		$unsunc_file.write("#{@concourse_ID}, Not on P&C for #{$sync_year}, "\
			"Check with School if you can delete it from Concourse\n")
	end

	def open_PandC
		#open the matching page in P&C
		url = "http://programsandcourses.anu.edu.au/"+$sync_year+"/course/"+@concourse_ID[0..7]
		encoded_url = URI.encode(url)
		@doc_PandC=Nokogiri::HTML(open(encoded_url))
		#puts "I'm in"
		$temp_file.write(@doc_PandC)
		#puts @doc_PandC

		# check Title
		@title = @doc_PandC.css('title').inner_html
		@title.slice!(" - ANU")
		if @title == "Page not found"
			return
		end
		if @title != @concourse_title
			# update Concourse to ensure titles match
			puts "#{@concourse_ID}: Update title from #{@concourse_title} to #{@title}"
			@out_of_sync += 1
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
			puts @in_year
			if @in_year != $sync_year
				#if the year written in P&C doens't match the year in the url, complain
				puts "#{@concourse_ID}: Something wrong with the scheduling year in PandC"
			end
			if @in_year != @concourse_year
				# update year in Concourse so it matches P&C
				puts "#{@concourse_ID}: Update Year from #{@concourse_year} to #{@in_year}"
				@out_of_sync += 1
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
					puts "#{@concourse_ID}: Update Session from #{@concourse_session}"\
					" to #{@in_session}"
					@out_of_sync += 1
				end
			end
		elsif @concourse_campus == "DRAFT"
			puts "#{@concourse_ID}: Not offered in #{$sync_year}, moving to Unused_DRAFT campus"
			@concourse_campus = "Unused_DRAFT"
			@out_of_sync += 1
		end

		#check College
		puts summary_headings
		college_heading = summary_headings.index("ANU College")
		puts college_heading
		str1_marker = summary_headings[college_heading]
		str2_marker = summary_headings[college_heading+1]
		college = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].to_s
		if college.split.count("College") > 1
			# if offered by more than one College, warn but don't change anything
			$unsunc_file.write("#{@concourse_ID}, Offered by more than one College,"\
				" No change has been made to the College or Department in Concourse.\n")
			@college = @concourse_college
		else
			@college = college.strip
			if @college != @concourse_college
				# if College in P&C doens't match Concourse, update in Concourse
				$unsunc_file.write("#{@concourse_ID}, P&C College #{@college} does not match "\
					"Concourse College #{@concourse_college},"\
					" No change has been made to the College or Department in Concourse.\n")
			end
			# check Offered by department
			offer_heading = summary_headings.index("Offered by")
			str1_marker = summary_headings[offer_heading]
			str2_marker = summary_headings[offer_heading+1]
			dept = summary_lines[/#{str1_marker}(.*?)#{str2_marker}/m, 1].to_s
			@by_dept = $concourse_department_name[dept.strip]
			if @by_dept == nil
				#if can't determine Department from P&C, warn but don't change in Concourse
				$unsunc_file.write(@concourse_ID + ", 'Offered By' in P&C not recognised,"\
				" No change has been made to the Department in Concourse\n")
				@by_dept = @concourse_department
			elsif @by_dept != @concourse_department
				#if Deparment in P&C doesn't match Concourse, update in Concourse
				puts "#{@concourse_ID}: Update the offering Department from #{@concourse_department} to #{@by_dept}"
				@out_of_sync += 1
				if @concourse_from_template != $school_template[dept.strip]
					$unsunc_file.write("#{@concourse_ID}, The Concourse draft is from the "\
						"#{@concourse_from_template} but it looks like it should be the "\
						"#{$school_template[dept.strip]},"\
						"This cannot be changed with Syllabus feed - if you want to change it "\
						"delete the Draft outline and make a replacement.\n")
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
 			puts "#{@concourse_ID}: Update the unit value from #{@concourse_credits}"\
 			" to #{@unit_value}"
 			@out_of_sync += 1
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
	 			$unsunc_file.write("#{@concourse_ID}, P&C delivery mode (#{@in_mode}) does not match"\
	 				" Concourse mode (#{@concourse_delivery}), No change has been made\n")
			end
		end	

 		# check convener / instructor
		convener_on_PandC = summary_headings.index("Course convener")
		if convener_on_PandC
			str1_marker = summary_headings[convener_on_PandC]
			str2_marker = summary_headings[convener_on_PandC+1]
			text = summary_lines.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1].strip
			@instructor = prepare_text_for_feed(text)
			#puts "#{@concourse_ID}: #{@instructor}"
			if @instructor != ""
				#puts "P&C has a name - is it the same as #{@concourse_instructor}?"
		 		if @concourse_instructor == "" #if Concourse doesn't list Instructor add from P&C
					@concourse_instructor = @instructor
					#puts "#{@concourse_ID}: add instructor #{@instructor}"
					@out_of_sync += 1
				elsif @instructor != @concourse_instructor 	#if Concourse does list Instructor, and it differs from P&C 
	 				#puts "no"
	 				if $sync_instructor == 1
	 					@out_of_sync += 1
	 					#puts "#{@concourse_ID}: change instructor from #{@concourse_instructor} to #{@instructor}"
						@concourse_instructor = @instructor		 			
	 				else #if Concourse does list Instructor, don't change it but warn if P&C doesn't match
	 					$unsunc_file.write("#{@concourse_ID}, P&C convener (#{@instructor}) does not match"\
	 						" Concourse instructor (#{@concourse_instructor}), No change has been made\n")

					end				
				else
					#puts "and so does Concourse and they match"
				end
			end
		end
 	end

	def write_course_feed(file,type)
		#write COURSE_IDENTIFIER|
		file.write("#{type == "Final"? @final_ID : @concourse_ID}|")
		#write TITLE|
		file.write("#{@title or 'error'}|")
		#write CAMPUS_IDENTIFIER|
		file.write("#{type=="Final" ? "FINAL" : @concourse_campus}|")
		#write DEPARTMENT_IDENTIFIER|
		file.write("#{@by_dept or 'error'}|")   
		#write START_DATE|
		file.write("01/01/#{$sync_year}|")   
		#write END_DATE|
		file.write("12/31/#{$sync_year}|")   
		#write CLONE_FROM_IDENTIFIER|
		file.write("#{type =="Final" ? @concourse_ID : @concourse_from_template}|")   
		#write TIMEZONE|
		file.write("Australia/Sydney|")
		#write PREFIX|
		file.write("#{@concourse_ID[0..3] or ''}|") 
		#write NUMBER|
		file.write("#{@concourse_ID[4..7] or ''}|") 
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
		file.write("#{type=="Draft" ? 1:0}|")
		#write HIDDEN_FROM_SEARCH
		file.write("0\n")
	end

	def write_section_feed(file,type)
		#write COURSE_IDENTIFIER|
		file.write("#{type =="Final" ? @final_ID : @concourse_ID}|")
		#write SECTION_IDENTIFIER|
 		file.write("#{type =="Final" ? @final_ID : @concourse_ID}_#{type}|")
 		#write SECTION_LABEL
		file.write("#{type}\n")
	end

	def prepare_text_for_feed(text0)
		if text0 == nil
			""
		else
			#puts text0
			all_words = ''
			if text0.include? "SUB-PLANS"
				str1_marker = ""
				str2_marker = " <!-- START SUB-PLANS -->"
				text = text0.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
			else
				text = text0
			end
			#puts "became" + text.to_s
			if text == nil
				#puts "which is nil"
				""
			else
				#puts "which I can do things with"
				text.gsub!('frameborder="0"',"") #maybe remove this
				text.gsub!(' allowfullscreen=""&gt;',"") # and this - they were put to fix one Crawford course video display 
				text.gsub!(/<div.*?>|<\/div>/, '')
				text.gsub!("<p><iframe", "<div><iframe") #is the div in the replacement necessary?
				text.gsub!("</iframe></p>", "</iframe></div>") #or here?
				text_lines = text.strip.lines
				text_lines.each do |words|
					words.gsub!(/\n/, ' ')
					words.gsub!(/\t/, ' ')
					all_words << " "
					all_words << words.strip 
				end	
				$temp_file.write(  "like make this")
				$temp_file.write( all_words)
				all_words
			end
		end
	end

	def get_PandC_description_LOs
		#temp_file.write(@doc_PandC.css('html'))
		search_html = @doc_PandC.css('div.introduction')
		$temp_file.write("#{@concourse_ID} \n")
		puts @concourse_ID
		$temp_file.write( search_html)
		puts
		pieces = search_html.inner_html.split("<h2")
		text = pieces[0]
		if text
			@description = prepare_text_for_feed(text)
		else 
			@description = "This course...."
		end

		search_html = @doc_PandC.css('div.body__inner').inner_html.to_s

		#find the Requisites and Incompatibilbity notices
		str1_marker = "Incompatibility</h2>"
		str2_marker = "<h2"
		text = search_html[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		if text
			@requisite = prepare_text_for_feed(text)
		else 
			@requisite = ""
		end

		#find the other notices (to go into Description Notes)
		str1_marker = "Other Information</h2>"
		str2_marker = "<h2"
		text0= search_html.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		if text0
			str1_marker = ""
			str2_marker = " <!-- START SUB-PLANS -->"
			text = text0.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
			if text
				@other = prepare_text_for_feed(text0)
			else 
				@other = ""
			end		
		else
			@other = ""
		end

		str1_marker = "Assumed Knowledge</h2>"
		str2_marker = "<h2"
		text0= search_html.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
		#puts text0
		if text0
			str1_marker = ""
			str2_marker = " <!-- START SUB-PLANS -->"
			text = text0.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]
			if text
				@other << "<strong> Assumed Knowledge </strong> <br>"
				@other << prepare_text_for_feed(text)
			end	
		end


		# find the LO's
		str1_marker = "Learning Outcomes</h2>"
		str2_marker = '<h2 id="indicative-assessment">'
		text = search_html.to_s[/#{str1_marker}(.*?)#{str2_marker}/m, 1]

		if text
			@LOs = prepare_text_for_feed (text)
		else 
			@LOs = "To be determined"
		end
	end

	def write_description_feed(file)
		#write COURSE_IDENTIFIER|
		file.write("#{@concourse_ID or 'error'}|")
		#write DESCRIPTION|
		file.write(@description+'|')
		#write REQUISITES|
		file.write(@requisite + '|')
		#write NOTES|
		file.write(@other + '|')
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#IS_LOCKED
		file.write("1\n")
	end

	def write_LO_feed(file)
		#write COURSE_IDENTIFIER|
		file.write(@concourse_ID + '|')
		#write OUTCOMES|
		file.write(@LOs + '|')
		#write NOTES|
		file.write("|")
		#write COMMENTS|
		file.write("written from P&C #{$timestamp}|")
		#write IS_LOCKED
		file.write("1\n")
	end

end

