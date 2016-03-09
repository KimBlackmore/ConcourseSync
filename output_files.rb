require 'fileutils'

def open_output_files(output_folder)
	FileUtils::mkdir_p output_folder
 
	puts "I'm going to overwrite files in  #{output_folder}"
	puts "If you don't want that, hit CTRL-C (^C)."
	puts "Else, hit RETURN."
	$stdin.gets

	puts "OK here goes..."

	course_feed_filename = output_folder+"/course_feed.csv"
	$course_feed_file = open(course_feed_filename,'w')
	$course_feed_file.truncate(0)
	$course_feed_file.write("COURSE_IDENTIFIER|TITLE|CAMPUS_IDENTIFIER|DEPARTMENT_IDENTIFIER|START_DATE|END_DATE|CLONE_FROM_IDENTIFIER|TIMEZONE|PREFIX|NUMBER|INSTRUCTOR|SESSION|YEAR|CREDITS|DELIVERY_METHOD|IS_STRUCTURED|IS_TEMPLATE|HIDDEN_FROM_SEARCH\n")

	if $task != "Sync"
		section_feed_filename = output_folder+"/section_feed.csv"
		$section_feed_file = open(section_feed_filename,'w')
		$section_feed_file.truncate(0)
		$section_feed_file.write("COURSE_IDENTIFIER|SECTION_IDENTIFIER|SECTION_LABEL\n")
	end

	if $task != "Finalise"
		description_feed_filename = output_folder+"/description_feed.csv"
		$description_feed_file = open(description_feed_filename,'w')
		$description_feed_file.truncate(0)
		$description_feed_file.write("COURSE_IDENTIFIER|DESCRIPTION|REQUISITES|NOTES|COMMENTS|IS_LOCKED\n")

		learningOutcomes_feed_filename = output_folder+"/LOs_feed.csv"
		$learningOutcomes_feed_file = open(learningOutcomes_feed_filename,'w')
		$learningOutcomes_feed_file.truncate(0)
		$learningOutcomes_feed_file.write("COURSE_IDENTIFIER|OUTCOMES|NOTES|COMMENTS|IS_LOCKED\n")

	 	unsunc_filename = output_folder+"/unsunc.csv"
		$unsunc_file = open(unsunc_filename,'w')
		$unsunc_file.truncate(0)
		$unsunc_file.write("COURSE_IDENTIFIER, Problem, You need to fix P&C or Concourse to resolve this. Or not. \n")
	end

	#for debugging:
	$temp_file = open("temp_file",'w')

end
 

