require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
require 'string-scrub'
load './output_files.rb' #the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods
load './concourse_names.rb' #mappings of P&C terminology to concourse 

$task = "Sync"
time = Time.new
$timestamp = time.strftime("_%Y-%m-%d")

#from October, sync Concourse drafts to P&C for the next year
if time.month <10
	$sync_year = time.year.to_s
else
	$sync_year = (time.year+1).to_s
end

#next open input file
concourse_syllabus_report = "Input/Concourse_Syllabus_report-all.csv"
puts "\n Check sync status for all the courses in the Concourse Syllabus report "\
	 "#{concourse_syllabus_report} with _Draft course ID.\n\n"

open_output_files("Output/SyncOutput")

$sync_instructor = 0
$add_noPC_to_titile = 0

CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	course = ANU_Course.new(x["Course Identifier"].to_s.strip)
	#puts course.concourse_ID
	if course.concourse_ID.include? "Draft" 
		course.get_Concourse_summary(x)
		if course.is_draft
			course.open_PandC
			if course.title == "Page not found"
				course.retire
				if course.out_of_sync > 0
					#puts '# of changes ' + course.out_of_sync.to_s
					course.write_course_feed($course_feed_file, "Draft")
				end
			else
				# get the info from P&C 
				if course.concourse_ID != course.code+"_Draft"
					$unsunc_file.write("#{course.concourse_ID}, Not a standard format course ID,"\
						"Will sync to #{course.code} on P&C\n")
				end
				course.get_PandC_info
				course.match_PandC_info
				# and use it to create feed files for updating Concourse
				if course.out_of_sync > 0
					#puts '# of changes ' + course.out_of_sync.to_s
					course.write_course_feed($course_feed_file, "Draft")
				end
				course.get_PandC_description_LOs
				course.write_description_feed($description_feed_file)
				course.write_LO_feed($learningOutcomes_feed_file)
			end
		else
			puts "unsunc"
			$unsunc_file.write("#{course.concourse_ID}, Not in Draft (or Unused_draft) campus in Concourse,"\
				"Sync process will skip this course\n")
		end
	#else
	#	$unsunc_file.write("#{course.concourse_ID}, Not a Draft outline,"\
	#		"Sync process will skip this course\n")
	end
end

puts
puts "You can now use the course, description and LO feed to update Concourse."
puts "Remember to check the unsunc file to see things you'll need to handle manually."
