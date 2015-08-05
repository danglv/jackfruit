module ApplicationHelper

	def help_get_title
		controller = params[:controller]
		action = params[:action]
		if (controller == "courses")
			help_get_courses_title(action)
		elsif (controller == "users")
			help_get_users_title(action)
		elsif (controller == "payment")
			help_get_payments_title(action)
		elsif (controller == "devise/sessions")
			help_get_sessions_title(action)
		elsif (controller == "devise/registrations")
			help_get_registrations_title(action)
		else
			title = "Tudemy"
		end
	end

	def help_get_courses_title(action)
		if (["select", "lecture", "learning", "detail"].include? action)
				title= if @course.blank?
					"Tudemy"
				else
					@course.name
				end
		elsif ["list_course_featured", "list_course_all"].include? action
			title= @category_name
		else
			title = "Khóa học"
		end
	end

	def help_get_users_title(action)
		if (["learning", "teaching", "wishlist"].include? action)
			"Khóa học của tôi"
		else
			"Tudemy"
		end
	end

	def help_get_payments_title(action)
		"Thanh toán"
	end

	def help_get_sessions_title(action)
		if (action == "create")
			"Đăng nhập"
		end
	end

	def help_get_registrations_title(action)
		if (action == "create")
			"Đăng ký"
		end
	end
end
