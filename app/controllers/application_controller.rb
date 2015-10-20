class ApplicationController < ActionController::Base
  include CoursesHelper

  before_filter :list_category, :store_location, :set_current_user, :get_banner, :handle_utm_source
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  
  def set_current_user
    User.current = current_user
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    return unless request.get? 
    if (request.path != "/users/sign_in" &&
        request.path != "/users/sign_up" &&
        request.path != "/users/password/new" &&
        request.path != "/users/password/edit" &&
        request.path != "/users/confirmation" &&
        request.path != "/users/sign_out" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
      session[:referer_url] = request.referer
    end
  end

  # Handling marketing chanel
  # How long this stuff will take, be very careful of this kind of work
  # Tested: 0.0 of excuting time
  def handle_utm_source
    # Check utm source from the request
    return unless request.get?
    utm_source = {}
    Constants::UTM_SOURCE.each do |key|
      utm_source[key] = params[key] if params[key]
    end
    # Save utm_source if has any
    unless utm_source.blank?
      session[:utm_source] = utm_source
    else
      # Clear utm source if user does something other than signin, signup, payment
      if session[:utm_source]
        if !params[:action].in?(['sign_in', 'sign_up', 'select_course', 'new']) && !params[:controller].in?(['payment'])
          session[:utm_source] = nil
        end
      end
    end
  end

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  # def authenticate_user
  #   current_user = User.where(auth_token: params[:auth_token]).first
  # end

  def validate_content_type_param
    @content_type = params[:content_type]
    @content_type = "html" if @content_type.blank?
  end

  # action index để điều hướng đến trang landing page
  def index
    if current_user
      redirect_to root_url + "courses"
      return
    end

    condition = {:enabled => true}

    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    courses_homepage = Course.where(condition).where(:label_ids.in => ["homepage"]).desc(:students).limit(8).to_a
    @courses = order_course_of_label('homepage', courses_homepage)

    # Get sale info for courses
    @sale_info = help_sale_info_for_courses @courses
  end

  def list_category
    @all_categories = []
    @parent_category_id = nil
    @level = 0

    categories_level_0 = Category.get_categories

    categories_level_0.each {|category|
      sub_categories = categories_level_0.select {|c| c.parent_category_id == category.alias_name}
      parent_cate = [category.alias_name, category.name, [], category.description]
      sub_categories.each {|sub_cate|
        parent_cate[2] << [sub_cate.alias_name, sub_cate.name]
      }
      @all_categories << parent_cate
    }
  end

  def validate_category
    @category_alias_name = params[:category_alias_name]
    @category = Category.where(alias_name: @category_alias_name).first
    if @category.blank?
      render 'page_not_found'
      return
    end
    @category_id = @category.id.to_s
  end

  def validate_course
    course_alias_name = params[:alias_name]
    condition = {:enabled => true, :alias_name => course_alias_name}

    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    @course = Course.where(condition).first

    if @course.blank?
      render 'page_not_found', status: 404
      return
    end
    # sort curriculums
    sort_curriculums
    
  end

  def get_banner
    layout = "#{params[:controller]}_#{params[:action]}"
    condition = {:layout => "#{layout}", :enabled => true}

    if current_user
      condition[:open_one_time_for_user] = true
      condition[:opened_user_ids.nin] = [current_user.id]
      @banner = Banner.where(condition).first

      if @banner
        @banner.opened_users << current_user if @banner.open_one_time_for_user == true
        @banner.save
      else
        @banner = Banner.where(:layout => layout, :enabled => true, :open_one_time_for_user => false).first
      end
    else
      @banner = Banner.where(condition).first
    end
  end

  def order_course_of_label(label_id, courses)
    begin
      courses.each do |c| 
        if !c['labels_order'].blank?
          order = c['labels_order'].detect{|label| 
            label['id'] == label_id
          }
          if !order.blank? 
            c['order'] = order['order'].to_i
          else
            c['order'] = 999
          end
        else
          c['order'] = 999
        end
      end
      courses.sort_by{|c| c['order']}
    rescue
      courses
    end
  end

  def handle_after_signin(resource)
    referer_url = session[:referer_url] if !session.blank?
    previous_url = session[:previous_url] if !session.blank?
    referer_url = previous_url if referer_url.blank?
    utm_source = session[:utm_source] if !session.blank?

    # Update wishlist
    wishlist_params = request.referer.blank? ? {} : (Rack::Utils.parse_query URI(request.referer).query)
    if !wishlist_params["course_id"].blank?
      course_id = wishlist_params["course_id"]
      resource.wishlist << course_id if (!(resource.wishlist.include? course_id) && !course_id.blank?)
      resource.save
    end

    if (!referer_url.blank?)
      url_components = referer_url.match(/([^\/]*)\/detail/)
      course_alias_name = url_components[1] if url_components
      course = Course.where(:alias_name => course_alias_name).first if !course_alias_name.blank?
      if !course.blank?
        owned_course = resource.courses.where(:course_id => course.id, :payment_status => Constants::PaymentStatus::SUCCESS).first
        if owned_course
          # Tracking L3d
          a = Spymaster.params.cat('L3d').beh('login').tar(course.id).user(resource.id).ext(utm_source).track(request)
        else
          # Tracking L3b
          b =Spymaster.params.cat('L3b').beh('login').tar(course.id).user(resource.id).ext(utm_source).track(request)
        end
      end
    end
  end

  def page_not_found
    condition = {}
    condition[:enabled] = true
    condition[:label_ids.in] = ["featured"]
    
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    @courses = Course.where(condition).desc(:students).limit(4).to_a
    @sale_info = help_sale_info_for_courses @courses
  end

  def server_error
    
  end

  def reset_password
    
  end

  private
    def sort_curriculums
      cus = []
      chapters = @course.curriculums.where(:type => "chapter")
      chapters.each do |chap|
        lecture_of_chap = @course.curriculums.where(:type => "lecture", :chapter_index => chap.chapter_index)
        cus +=(chap.to_a + lecture_of_chap.to_a.sort_by{|lec| lec.lecture_index})
      end
      @course.curriculums = cus
    end
end