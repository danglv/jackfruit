namespace :course_utils do

  desc "Set relative courses for all courses"
  task batch_set_relatives: :environment do
  	puts "Working on environment #{Rails.env}"

  	# List of relative courses
  	relatives = [
  		"55cb2d3044616e15ca000000", # Giam can ma khong can an kieng
  		"55c312f344616e0ca6000000", # Tieng anh ung dung
  		"55c3306344616e0ca600001f", # Lam chu excel trong 4h
  		"55b1c17152696418a000005b"] # Dau cau khong kho

  	# Get relative courses
  	relative_courses = []
  	relatives.each do |id|
  		course = Course.where(:id => id).first
  		relative_courses << course if course
  	end

  	puts "List of relative courses: ", relative_courses.map{|c| c.alias_name}

  	# Set relative courses for all courses
  	Course.each do |course|
  		puts "Course: #{course.alias_name}"
  		course.relatives.clear
  		course.relatives << relative_courses
  	end

  	puts "Almost done ..."
  	# Delete relative course which is same as course
  	relative_courses.each do |course|
      course.reload
  		course.relatives.delete course
  	end

  	puts "Done!"
  end

end