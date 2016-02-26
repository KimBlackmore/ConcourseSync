
#mappings of P&C terminology to concourse
#
#
$session_name = {
	"First"=> "Semester 1", 
	"Second" => "Semester 2",
	"Summer" => "Summer",
	"Autumn" => "Autumn",
	"Winter" => "Winter",
	"Spring" => "Spring" 
}

$concourse_department_name = {
	"ANU College of Asia and the Pacific" => "CHL",
	"ANU National Security College" => "Crawford",
	"Asia-Pacific College of Diplomacy" => "Bell",
	"Australian Centre on China in the World" => "CIW",
	"Coral Bell School of Asia Pacific Affairs" => "Bell",
	"Crawford School of Public Policy" => "Crawford",
	"Department of International Relations" => "Bell",
	"Department of Political and Social Change" => "Bell",
	"International and Development Economics Program" => "Crawford",
	"Policy and Governance Program" => "Crawford",
	"Regulatory Institutions Network Program" => "RJD",
	"Research School of Management" => "RSM",
	"Resource Management in Asia Pacific" => "Crawford",
	"School of Culture History and Language" => "CHL",
	"School of Culture, History &amp; Language" => "CHL",
	"Strategic and Defence Studies Centre" => "Bell"
}

$school_template = {
	"ANU College of Asia and the Pacific" => "CHL_Template",
	"ANU National Security College" => "NSC_Template",
	"Asia-Pacific College of Diplomacy" => "Bell_Template",
	"Australian Centre on China in the World" => "CIW_Template",
	"Bell School Template" => "Bell_Template",
	"Coral Bell School of Asia Pacific Affairs" => "Bell_Template",
	"CHL Template" => "CHL_Template",
	"Crawford School of Public Policy" => "Crawford_Template",
	"Crawford Template" => "Crawford_Template",
	"Department of International Relations" => "Bell_Template",
	"Department of Political and Social Change" => "Bell_Template",
	"International and Development Economics Program" => "Crawford_Template",
	"NSC Template" => "NSC_Template",
	"Policy and Governance Program" => "Crawford_Template",
	"Regulatory Institutions Network Program" => "RJD_Template",
	"Research School of Management" => "RSM_Template",
	"Resource Management in Asia Pacific" => "Crawford Template",
	"RSM Template" => "RSM_Template",
	"School of Culture History and Language" => "CHL_Template",
	"Strategic and Defence Studies Centre" => "Bell_Template"
}

=begin
class OutputWriter 

	def open_files
		time = Time.new
		$timestamp = time.strftime("_%Y-%m-%d")
		course_feed_filename = "PandCoutput/PandC_course_feed"+$timestamp
		description_feed_filename = "PandCoutput/PandC_description_feed"+$timestamp
		section_feed_filename = "PandCoutput/PandC_section_feed"+$timestamp
		learningOutcomes_feed_filename = "PandCoutput/PandC_LO_feed"+$timestamp
		puts "I'm going to overwrite #{course_feed_filename or 'error!'}"
		puts "...and #{description_feed_filename or 'error!'}"
		puts "...and #{learningOutcomes_feed_filename or 'error!'}"
		puts "If you don't want that, hit CTRL-C (^C)."
		puts "If you do want that, hit RETURN."

		$stdin.gets

		puts "OK here goes..."


		$course_feed_file = open(course_feed_filename,'w')
		$course_feed_file.truncate(0)
		$course_feed_file.write("COURSE_IDENTIFIER|TITLE|CAMPUS_IDENTIFIER|DEPARTMENT_IDENTIFIER|START_DATE|END_DATE|CLONE_FROM_IDENTIFIER|TIMEZONE|PREFIX|NUMBER|INSTRUCTOR|SESSION|YEAR|CREDITS|DELIVERY_METHOD|IS_STRUCTURED|IS_TEMPLATE|HIDDEN_FROM_SEARCH\n")

		$description_feed_file = open(description_feed_filename,'w')
		$description_feed_file.truncate(0)
		$description_feed_file.write("COURSE_IDENTIFIER|DESCRIPTION|REQUISITES|NOTES|COMMENTS|IS_LOCKED\n")

		$section_feed_file = open(section_feed_filename,'w')
		$section_feed_file.truncate(0)
		$section_feed_file.write("COURSE_IDENTIFIER|SECTION_IDENTIFIER|SECTION_LABEL\n")

		$learningOutcomes_feed_file = open(learningOutcomes_feed_filename,'w')
		$learningOutcomes_feed_file.truncate(0)
		$learningOutcomes_feed_file.write("COURSE_IDENTIFIER|OUTCOMES|NOTES|COMMENTS|IS_LOCKED\n")
	end
end
# 
=end

