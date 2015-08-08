namespace :reports do
	desc "Report user get course free"
  task report_user_get_course_free: :environment do
  	
		dir_path = "public/reports/"
    FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)
    file_name = dir_path + "user_get_course_free.csv"
    File.open(file_name, "w") {|csv| 
    	a = 0
    	csv << ["Name", "Email", "Các Course free user "]
			User.where(:label_ids.nin => ["test_user"]).each {|u|
				if u.courses.count > 0
					result = [u.name, u.email]
					courses = []
					u.courses.each {|c|
						if !c.course.blank?
							if c.course.price == 0
								a += 1 
								courses << c.course.name
							end
						end
					}
					result << courses
					csv << result if courses.count > 0
				end
			}
    }
  end
end