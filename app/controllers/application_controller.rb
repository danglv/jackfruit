class ApplicationController < ActionController::Base
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
    @courses = Course.all.desc(:students).limit(8)

    if current_user
      redirect_to root_url + "courses"
    end

  end

  def list_category
    @all_categories = []
    @parent_category_id = nil
    @level = 0

    categories_level_0 = Category.get_categories

    categories_level_0.each {|category|
      sub_categories = categories_level_0.select {|c| c.parent_category_id == category.id}
      parent_cate = [category.id, category.name, []]
      sub_categories.each {|sub_cate|
        parent_cate[2] << [sub_cate.id, sub_cate.name]
      }
      @all_categories << parent_cate
    }
  end

  def validate_category
    @category_id = params[:category_id]
    @category = Category.where(id: @category_id).first

    if @category.blank?
      render 'page_not_found'
      return
    end
  end

  def validate_course
    course_alias_name = params[:alias_name]
    @course = Course.where(alias_name: course_alias_name).first

    if @course.blank?
      render 'page_not_found', status: 404
      return
    end
  end

  def get_banner
    layout = "#{params[:controller]}_#{params[:action]}"
    @banner = Banner.where(layout: layout, enabled: true).first
  end
end