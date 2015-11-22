module CoursesHelper

	def help_sale_info_for_course_set(course_set)
		sale_infos = {}
		course_set.each do |set|
			set.last.last.each do |course|
				if course.price > 0
					sale_info = Sale::Services.get_price(:course => course)
					sale_infos[course.id] = sale_info if sale_info[:final_price] > 0
				end
			end
		end
		sale_infos
	end

	def help_sale_info_for_courses(courses)
		sale_infos = {}
		courses.each do |course|
			if course.price > 0
				sale_info = Sale::Services.get_price(:course => course)
				sale_infos[course.id] = sale_info if sale_info[:final_price] > 0
			end
		end
		sale_infos
	end
end