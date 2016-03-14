require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
require 'diffy'
load './output_files.rb' #the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods
load './concourse_names.rb' #mappings of P&C terminology to concourse 

$task = "Finalise"
$time = Time.new
$timestamp = $time.strftime("_%Y-%m-%d")
#from October, sync Concourse drafts to P&C for the next year
if $time.month <10
	$sync_year = $time.year.to_s
else
	$sync_year = ($time.year+1).to_s
end


#next open input file
concourse_syllabus_report = "Input/Concourse_Syllabus_report_to_final.csv"
puts "I will make final copies for all the draft courses in "\
	 "#{concourse_syllabus_report} that have been reviewed in the last 3 months "\
	 "AND don't already have a final copy that I can find in the Syllabus Report."
puts "If you don't want that, hit CTRL-C (^C)."
puts "Else, hit RETURN."
$stdin.gets

puts "OK here goes..."
open_output_files("FinaliseOutput")

$sync_instructor = 1

$courselist = Set.new
CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	$courselist.add(x["Course Identifier"])
end


CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	course = ANU_Course.new(x["Course Identifier"].to_s.strip)
	if course.concourse_ID.include? "Draft" 
		course.get_Concourse_summary(x)
		puts course.concourse_ID 
		course.check_audit_status
		if course.to_finalise >0
			puts "Finalise #{course.concourse_ID}"
			course.make_final
			course.write_course_feed($course_feed_file, "Final")
			course.write_section_feed($section_feed_file, "Final")
		end
	end
end

