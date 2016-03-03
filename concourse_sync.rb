require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
load './output_files.rb' #the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods
load './concourse_names.rb' #mappings of P&C terminology to concourse 

time = Time.new
$timestamp = time.strftime("_%Y-%m-%d")
#from October, sync Concourse drafts to P&C for the next year
if time.month <10
	$sync_year = time.year.to_s
else
	$sync_year = (time.year+1).to_s
end

open_output_files("SyncOutput")

concourse_syllabus_report = "Concourse_Syllabus_report.csv"

#puts "Where is the syllabus report for me to sync?"
#concourse_syllabus_report = gets.to_s

puts "I will check sync status for all the courses in the Concourse Syllabus report "\
	 "#{concourse_syllabus_report}"

CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	course = ANU_Course.new
	course.get_Concourse_summary(x)
	#puts course.concourse_ID + " "+ course.concourse_title
	if course.concourse_ID.include? "Draft" 
		#puts course.concourse_ID
		if course.is_draft
			course.open_PandC
			if course.title == "Page not found"
				# alert if any of the Draft outlines in Concourse are not in P&C fo sync_year
				puts "unsunc"
				$unsunc_file.write("#{course.concourse_ID}, Not on P&C for #{$sync_year}, "\
					"Check with School if you can delete it from Concourse\n")
			else
				# get the info from P&C 
				if course.concourse_ID != course.code+"_Draft"
					puts  "Not a standard format course ID,"\
						"So will sync to #{course.code} on P&C\n"
				end
				course.match_PandC_summary
				# and use it to create feed files for updating Concourse
				if course.out_of_sync==1
					course.write_course_feed($course_feed_file)
					course.write_section_feed($section_feed_file)
				end
				course.get_PandC_description_LOs
				course.write_description_feed($description_feed_file)
				course.write_LO_feed($learningOutcomes_feed_file)
			end
		else
			puts "unsunc"
			$unsunc_file.write("#{course.concourse_ID}, Not in Draft (or Unused_draft) campus in Concourse,"\
				"Sync process will skip this course")
		end
	else
		$unsunc_file.write("#{course.concourse_ID}, Not a Draft outline,"\
			"Sync process will skip this course")
	end
end

