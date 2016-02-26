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
#from October, sync Concourse drafts to P&C for the next year
if time.month <10
	$sync_year = time.year.to_s
else
	$sync_year = (time.year+1).to_s
end
	
#prefix_list = Set.new
starter = OutputWriter.new
starter.open_files


concourse_syllabus_report = 'ConcourseOutput/Syllabus_report_tricky.csv'
puts "I will check sync status for all the courses in the Concourse Syllabus report #{concourse_syllabus_report}"
concourse_courses = CSV.read(concourse_syllabus_report, :encoding => 'windows-1251:utf-8')

for i in 1..(concourse_courses.length-1)
	prefix = concourse_courses[i][1][0..3]
	#prefix_list.add(prefix)
	number = concourse_courses[i][1][4..7]

	#open the matching page in P&C
	url = "http://programsandcourses.anu.edu.au/"+$sync_year+"/course/"+prefix+number
	encoded_url = URI.encode(url)
	doc=Nokogiri::HTML(open(encoded_url))

	existsInPandC = doc.css('h1.intro__landing-title').inner_html.strip
	# alert if any of the Draft outlines in Concourse for 2016 are not in P&C
	if existsInPandC == "The page you are looking for doesn't exist"
		$unsunc_file.write("#{prefix}#{number} does not appear on P&C for #{$sync_year} - check with School if you can delete it from Concourse\n")
	else
		course = ANU_Course.new
		course.get_Concourse_summary(concourse_courses[i])
		course.get_PandC_summary(doc)

		if course.out_of_sync==1
			course.write_course_feed($course_feed_file)
			course.write_section_feed($section_feed_file)
		end
		
		course.get_PandC_description_LOs(doc)
		course.write_description_feed($description_feed_file)
		course.write_LO_feed($learningOutcomes_feed_file)
	end
end




#puts (course.no_of_courses).to_s+" courses from the following subjects: "
#p prefix_list



# How to hunt down course outlines in P&C that arent' in Concourse at all?
# Note if its in P&C catalogue but isn't actually offered in upcoming, don't care if it isn't in Concourse
