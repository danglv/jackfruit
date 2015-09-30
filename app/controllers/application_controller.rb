class ApplicationController < ActionController::Base
  include CoursesHelper

  before_filter :list_category, :store_location, :set_current_user, :get_banner
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

    @courses = Course.where(condition).where(:label_ids.in => ["homepage"]).desc(:students).limit(8)

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
    @category_id = @category.id.to_s

    if @category.blank?
      render 'page_not_found'
      return
    end
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

  def after_sign_in_path_for(resource)
    last_url = request.referer
    uri = URI(last_url) if !last_url.blank? || last_url.is_a?(String)
    course_id = nil
    
    if uri != nil
      if !uri.query.blank?
        params = URI::decode_www_form(uri.query).to_h
        course_id = params["course_id"]
      end
    end

    if ((resource.is_a? User) && !course_id.blank?)
      resource.wishlist << course_id if !(resource.wishlist.include? course_id) && course_id != nil
      resource.save
    end
    session[:previous_url] || request.env['omniauth.origin'] || stored_location_for(resource) || root_path
  end
end