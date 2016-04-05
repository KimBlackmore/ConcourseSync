require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
load './output_files.rb' #the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods
load './concourse_names.rb' #mappings of P&C terminology to concourse 

$task = "Add_drafts"
time = Time.new
$timestamp = time.strftime("_%Y-%m-%d")
#from October, sync Concourse drafts to P&C for the next year
if time.month <10
	$sync_year = time.year.to_s
else
	$sync_year = (time.year+1).to_s
end

puts "\n Read the list of coursecodes in P&C_courselist.csv - ",
	"should be a file with one coursecode on each line - headers to match search in P&C.\n"

pandC_courselist = "Input/P&C_courselist.csv" #this should be a file with a course code on each line

concourse_syllabus_report = "Input/Concourse_Syllabus_report-all.csv"
puts "\n For each coursecode will check if there is already a draft courseoutline with ",
	"ID coursecode_Draft in #{concourse_syllabus_report}. If not will create entries ",
	"in course feed and syllabus feed files.\n\n"

open_output_files("Add_draft_output")

$courselist = Set.new
CSV.foreach(concourse_syllabus_report, :headers => true) do |x| 
	$courselist.add(x["Course Identifier"])
end
#$courselist.each { |element| $temp_file.puts(element) }


CSV.foreach(pandC_courselist, :headers => true) do |x| 
	course_ID = x["CODE"]+"_Draft"
	if $courselist.include? course_ID
		#puts course_ID + " is already in Concourse"
	else
		course = ANU_Course.new(course_ID)
		$courselist.add(course_ID)
		course.open_PandC  
		if course.title != "Page not found"
			puts "Add #{course_ID} to feeds"
			course.get_PandC_info
			course.create_feed_info
			course.write_course_feed($course_feed_file,"Draft")
			course.write_section_feed($section_feed_file,"Draft")
			course.get_PandC_description_LOs
			course.write_description_feed($description_feed_file)
			course.write_LO_feed($learningOutcomes_feed_file)
			$courselist.add(course_ID)
		end
	end
end

