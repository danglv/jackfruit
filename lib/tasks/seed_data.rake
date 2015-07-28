namespace :seed_data do

  desc "Import instructors from csv to database including their courses"
  task :instructor => :environment do
  	# Load data
    puts "Loading data from csv file ..."
  	data = load_csv_file_for("instructor", "instructor_premium")
  	unless data
  		puts "Could not read data from csv file!"
  		return
  	end

    puts "Parsing data ..."
  	header = data.shift

  	instructors = []

  	info = data.shift
  	while (info)
		  instructor = {}
		  courses = []
  		instructor["name"] 									      = info[1]
  		instructor["alias_name"] 							    = info[2]
  		instructor["image"] 								      = info[3]
  		instructor["instructor_profile"] 					= {}
  		instructor["instructor_profile"]["academic_rank"] 	= info[4]
  		instructor["instructor_profile"]["major"] 			    = info[5]
  		instructor["instructor_profile"]["function"] 		    = info[6]
  		instructor["instructor_profile"]["work_unit"] 		  = info[7]
  		courses << info[8]
  		info = data.shift
  		while (info && info[1].blank?)
  			# There may be more courses
  			courses << info[8]
  			info = data.shift
 		end
  		instructor["courses"] = courses
  		instructors << instructor
  	end
    puts "Total of instructors: #{instructors.count}"
    puts "Updating to database ..."
  	instructors.each do |i|
  		new_instructor(i)
  	end
    puts "Work done! Happy Coding"
  end

end

# Create new instructor and save to database
def new_instructor(instructor)
  # puts "Creating new instructor #{instructor["name"]} ..."
	email = instructor["alias_name"] + "." + Time.now.to_i.to_s + "@gmail.com"
	password = "123456"
	user = User.new(
		:email => email,
		:password => password,
		:password_confirmation => password
	)
	user.instructor_profile = User::InstructorProfile.new(
		:academic_rank 	=> instructor["instructor_profile"]["academic_rank"],
		:major 			    => instructor["instructor_profile"]["major"],
		:function 		  => instructor["instructor_profile"]["function"],
		:work_unit 		  => instructor["instructor_profile"]["work_unit"]
	)
	user.name = instructor["name"]
	user.avatar = instructor["image"]
  user.save
  update_course_owner(user, instructor["courses"])
end

def update_course_owner(user, courses)
  # puts "Update courses for instructor: #{user.name}"
  courses.each do |course_alias|
    course = Course.where(:alias_name => course_alias).first
    if (course)
      course.user = user
      course.save
    else
      puts "Count not find course: #{course_alias}"
    end
  end
end

def load_csv_file_for(dir, file_name)
	file = "db/seeding_data/version1.0.3/#{dir}/#{file_name}.csv"
	data = CSV.parse(File.read(file))
end