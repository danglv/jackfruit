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

  def help_get_user_lang_list
    list = Constants::UserLang.constants
    langs = {}
    list.each do |name|
      lang = Constants::UserLang.const_get(name)
      langs[lang] = Constants::USER_LANG_MAPPING[lang]
    end
    return langs
  end

	def help_show_currency(price)
		number_to_currency(price, :locale => 'vi', :unit => 'đ', :precision => 0, :delimiter => ",", :format => "%n%u")
	end

	def self.pagination(sources, page = 0, number_element_of_page = 5)
    return {:objects => [], :current_page => page, :total => 0} if (sources.count == 0)
    number_element_of_page = number_element_of_page == 0 ? 5 : number_element_of_page 
    total = sources.count / number_element_of_page
    elements = []
    if page <= 0
    	elements = sources[0..(number_element_of_page - 1)]
    elsif page >= total
    	elements = sources[((total - 1) * number_element_of_page)..sources.last]
    else
    	elements = sources[(page * number_element_of_page)..(((page+1) * number_element_of_page) - 1)]
    end
    return {:elements => elements, :current_page => page, :total => total}
	end

  def help_build_buying_course_url(sale_info, course)
    url = "/home/my-course/select_course?alias_name=#{course.alias_name}&type=learning"

    url + (sale_info[:coupon_code] ? "&coupon_code=#{sale_info[:coupon_code]}" : '')
  end

  def help_build_payment_method_url(link, data)
    link += link.index('?').blank? ? '?' : ''
    link + (data[:coupon_code] ? "&coupon_code=#{data[:coupon_code]}" : '')
  end

  def help_get_user_name
    if current_user
      if !current_user.first_name.blank? && !current_user.last_name.blank?
        return current_user.first_name + " " + current_user.last_name
      else
        return current_user.name || ""
      end
    end
    return ""
  end

  def help_get_user_email
    if current_user
      return current_user.email
    end
  end
end
