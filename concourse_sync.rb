require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
require 'string-scrub'
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

#next open input file
concourse_syllabus_report = "Concourse_Syllabus_report.csv"
puts "I will check sync status for all the courses in the Concourse Syllabus report "\
	 "#{concourse_syllabus_report}"

$sync_instructor = 1

CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	course = ANU_Course.new(x["Course Identifier"].to_s.strip)
	#puts course.concourse_ID
	if course.concourse_ID.include? "Draft" 
		course.get_Concourse_summary(x)
		if course.is_draft
			course.open_PandC
			if course.title == "Page not found"
				course.retire
				if course.out_of_sync==1
					course.write_course_feed($course_feed_file, "Draft")
				end
			else
				# get the info from P&C 
				if course.concourse_ID != course.concourse_ID[0..7]+"_Draft"
					$unsunc_file.write("#{course.concourse_ID}, Not a standard format course ID,"\
						"Will sync to #{course.concourse_ID[0..7]} on P&C\n")
				end
				course.match_PandC_summary
				# and use it to create feed files for updating Concourse
				if course.out_of_sync==1
					course.write_course_feed($course_feed_file, "Draft")
				end
				course.get_PandC_description_LOs
				course.write_description_feed($description_feed_file)
				course.write_LO_feed($learningOutcomes_feed_file)
			end
		else
			#puts "unsunc"
			$unsunc_file.write("#{course.concourse_ID}, Not in Draft (or Unused_draft) campus in Concourse,"\
				"Sync process will skip this course\n")
		end
	else
		$unsunc_file.write("#{course.concourse_ID}, Not a Draft outline,"\
			"Sync process will skip this course\n")
	end
end

puts "You can now use the course, description and LO feed to update Concourse."
puts "Remember to check the unsunc file to see things you'll need to handle manually."
