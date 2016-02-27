require 'fileutils'

class OutputWriter 

	def open_files
		#time = Time.new
		#$timestamp = time.strftime("_%Y-%m-%d")
		output_folder = "SyncOutput"+$timestamp
		FileUtils::mkdir_p output_folder


		course_feed_filename = output_folder+"/courses_from_PandC"
		description_feed_filename = output_folder+"/descriptions_from_PandC"
		section_feed_filename = output_folder+"/section_from_PandC"
		learningOutcomes_feed_filename = output_folder+"/LOs_from_PandC"
		#unused_courses_filename = output_folder+"/PandC_to_unused"
		testoutput_filename = output_folder+"/testout"
		unsunc_filename = output_folder+"/unsunc"

		puts "I'm going to overwrite files in  #{output_folder}"
		puts "If you don't want that, hit CTRL-C (^C)."
		puts "Else, hit RETURN."

		$stdin.gets

		puts "OK here goes..."

		$testoutputfile = open(testoutput_filename,'w')
		$testoutputfile.truncate(0)

		$unsunc_file = open(unsunc_filename,'w')
		$unsunc_file.truncate(0)
		$unsunc_file.write("These things don't match in P&C and Concourse - you need to fix one or the other. Or not.\n")

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

		#$unused_courses_file = open(unused_courses_filename,'w')
		#$unused_courses_file.truncate(0)
		#$unused_courses_file.write("Move all of the following to the Concourse Unused_draft campus|\n")
	end
end
# 

