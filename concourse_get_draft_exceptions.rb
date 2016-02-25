require 'nokogiri'
require 'open-uri'
require 'action_view'
require 'csv'
require 'set'
load './concourse_names.rb' #mappings of P&C terminology to concourse 
load './output_files.rb' #the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods

time = Time.new
$timestamp = time.strftime("_%Y-%m-%d")

output_folder = "SyncOutput"+$timestamp
FileUtils::mkdir_p output_folder

exception_list_filename = output_folder+"/Concourse_ID_exceptions"
puts "I'm going to overwrite #{exception_list_filename or 'error!'}"
puts "If you don't want that, hit CTRL-C (^C)."
puts "If you do want that, hit RETURN."

$stdin.gets

puts "OK here goes..."

$exception_list_file = open(exception_list_filename,'w')
$exception_list_file.truncate(0)

#puts "Enter the path to your Concourse Syllabus report"
#concourse_draft_IDs = gets.to_s
#puts "Reading the course list in #{concourse_draft_IDs}"
#concourse_courses = CSV.read("./"+concourse_draft_IDs, :encoding => 'windows-1251:utf-8')

concourse_syllabus_report = 'ConcourseOutput/Syllabus_report.csv'
puts "Reading the course list in #{concourse_syllabus_report}"
concourse_courses = CSV.read(concourse_syllabus_report, :encoding => 'windows-1251:utf-8')

for i in 1..(concourse_courses.length-1)
	course_ID = concourse_courses[i][1]
	if course_ID.length > 14
		puts course_ID
		$exception_list_file.write(course_ID+"\n")
	end
end
	