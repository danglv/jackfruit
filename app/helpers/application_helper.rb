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
			title = "Pedia"
		end
	end

	def help_get_courses_title(action)
		if (["select", "lecture", "learning", "detail"].include? action)
				title= if @course.blank?
					"Pedia"
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
			"Pedia"
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

	def help_get_youtube_url lecture
		if lecture.url.index('v=').blank?
			indexStart = lecture.url.index('.be/') + 4
			youtube_id = lecture.url[indexStart..lecture.url.length]
		else
			indexStart = lecture.url.index('v=') + 2
		end
		if lecture.url['&']
			indexEnd = lecture.url.index('&')-1
			youtube_id = lecture.url[indexStart..indexEnd]
		else
			indexEnd = lecture.url.length
			youtube_id =  lecture.url[indexStart..indexEnd]
		end
		if youtube_id
			return 'https://www.youtube.com/embed/' + youtube_id + '?modestbranding=0&amp;rel=0&amp;showinfo=0'
		else
			return ""
		end
	end

end
