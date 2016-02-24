require 'nokogiri'
require 'open-uri'
require 'action_view'
load './concourse_names.rb' #mappings of P&C terminology to concourse and the bits for opening all the right files
load './ANU_course.rb' #define the course class and its methods

# see help with cleaning here http://kevinquillen.com/programming/2014/06/23/ruby-gets-shit-done
# 
# open feed files
starter = OutputWriter.new
starter.open_files

# for each coursecode in P&C

prefix = "ASIA"
number = "2107"

course = ANU_Course.new

course.set_code(prefix,number)
course.get_PandC()
	# check if they match the Concourse properties
	# if not warn 
	# 	- including if course is not in Concourse at all
	# 	- or is in unused_drafts
	# and add lines feed files to fix it

course.write_course_feed($course_feed_file)
course.write_section_feed($section_feed_file)
course.write_description_feed($description_feed_file)
course.write_LO_feed($learningOutcomes_feed_file)


# for each coursecode in Concourse drafts
	# check if the course is in P&C
	# if not warn
	# and write code to a "to_be_deleted or moved to unused" file
	# 
	# 

