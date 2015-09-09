class UsersController < ApplicationController
  before_action :set_user, :except => [:suggestion_search, :active_course, :get_user_detail]
  before_filter :authenticate_user!, only: [:learning, :teaching, :wishlist, :select_course, :index]
  before_filter :validate_course, only: [:select_course]

  def index
    learning
  end

  def sign_up_with_email
    email = params[:email]
    password = params[:password]
    platform   = params[:platform]

    email_regex = %r{^[0-9a-z][0-9a-z._+]+[0-9a-z]@[0-9a-z][0-9a-z.-]+[0-9a-z]$}xi

    if email.blank? || (email =~ email_regex) != 0
      render json: {message: "Vui lòng nhập lại email!"}, status: :unprocessable_entity
      return
    end

    if password.blank?
      render json: {message: "Vui lòng nhập password!"}, status: :unprocessable_entity
      return
    end

    unless check_valid_length(password, 6, 32)
      render json: {message: "Vui lòng nhập đủ ký tự cho password!"}, status: :unprocessable_entity  
      return
    end

    user = User.only(:email).where(email: email).first

    unless user 
      render json: {message: "Email này đã được sử dụng!"}
      return
    end

    User.new(
      :email => email,
      :password => password,
      :password_confirmation => password
    )

    head :ok
  end

  # def login_with_email

  # end

  # def login_with_facebook
    
  # end

  # def login_with_google
    
  # end

  # def logout

  # end

  # def edit_profile
    
  # end

  # def upload_avatar
    
  # end

  def learning
    learning = Constants::OwnedCourseTypes::LEARNING
    course_ids = current_user.courses.where(
      :type => learning,
    ).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

  end

  def teaching
    teaching = Constants::OwnedCourseTypes::TEACHING
    course_ids = current_user.courses.where(type: teaching).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def wishlist
    # wishlist = Constants::OwnedCourseTypes::WISHLIST
    # course_ids = current_user.courses.where(type: wishlist).map(&:course_id)
    # @courses = Course.where(:id.in => course_ids)

    # head :ok
  end

  def search
    keywords = params[:q]
    keywords = Utils.nomalize_string(keywords)
    pattern = /#{Regexp.escape(keywords)}/
    @courses = []
    current_user.courses.map{|owned_course|
      @courses << owned_course.course if (owned_course.course.alias_name =~ pattern) == 0
    }

    head :ok
  end

  def select_course
    if @course.price == 0
      owned_course = current_user.courses.where(course_id: @course.id).first
      if owned_course.blank?
        owned_course = current_user.courses.create(course_id: @course.id, created_at: Time.now())
        UserGetCourseLog.create(course_id: @course.id, user_id: current_user.id, created_at: Time.now())
      end

      if @course.price != 0
        status = Constants::PaymentStatus::PENDING
      else
        status = Constants::PaymentStatus::SUCCESS
      end

      owned_course.type = Constants::OwnedCourseTypes::LEARNING
      owned_course.payment_status = status

      init_lectures_for_owned_course(owned_course, @course)

      if current_user.save
        redirect_to root_url + "courses/#{@course.alias_name}/select"
        return
      else
        redirect_to root_url + "courses"
        return
      end
    else
      url = root_url + "home/payment/#{@course.alias_name}"
      url += "?coupon_code=#{params['coupon_code']}" if !params['coupon_code'].blank?
      redirect_to url
    end
  end

    # GET /users/:id.:format
  def show
    # authorize! :read, @user
    render json: @user
  end

  # GET /users/:id/edit
  def edit
    # authorize! :update, @user
    render json: @user
  end

  # PATCH/PUT /users/:id.:format
  def update
    # authorize! :update, @user
    respond_to do |format|
      if @user.update(user_params)
        sign_in(@user == current_user ? @user : current_user, :bypass => true)
        format.html { redirect_to @user, notice: 'Your profile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET: API suggestion search for user by name
  def suggestion_search
    keywords = params[:q]
    keywords = Utils.nomalize_string(keywords)
    pattern = /#{Regexp.escape(keywords)}/

    users = User.where(:name => pattern).map { |user|
      UserSerializer.new(user).suggestion_search_hash
    }

    render json: users, root: false
    return
  end

  # POST: API active course for user (mercury)
  def active_course
    course_id = params[:course_id]
    user_id = params[:user_id]
    user = User.find(user_id)

    owned_course = user.courses.where(course_id: course_id).first
    owned_course.payment_status = Constants::PaymentStatus::SUCCESS

    if user.save
      render json: {message: "Thành công!"}
      return
    else
      render json: {message: "Thất bại!"}
      return
    end
  end

  # GET: API get user info & course of user
  def get_user_detail
    user_id = params[:id]
    user = User.find(user_id)

    render json: UserSerializer.new(user).profile_detail_hash
  end

  # GET/PATCH /users/:id/finish_signup
  def finish_signup

    # authorize! :update, @user 
    if request.patch? && params[:user] #&& params[:user][:email]
      if @user.update(user_params)
        @user.skip_reconfirmation!
        sign_in(@user, :bypass => true)
        redirect_to @user, notice: 'Your profile was successfully updated.'
      else
        @show_errors = true
      end
    end
  end

  # DELETE /users/:id.:format
  def destroy
    # authorize! :delete, @user
    @user.destroy
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

  private
    def set_user
      if params[:id] != nil
        @user = User.find(params[:id]) 
      else
        @user = current_user
      end
      # Fix user đầu tiên để demo
      # @user = User.first if @user == nil
    end
    def user_params
      accessible = [ :name, :email ] # extend with your own params
      accessible << [ :password, :password_confirmation ] unless params[:user][:password].blank?
      params.require(:user).permit(accessible)
    end

    def init_lectures_for_owned_course(owned_course, course)
      course.curriculums.where(
        :type => Constants::CurriculumTypes::LECTURE
      ).map{|curriculum|
        owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
      }

      course.set(:students => course.students + 1)
    end

    def check_valid_length(string, min_length, max_length)
      string.length >= min_length && string.length <= max_length
    end

  def view_profile
    
  end
end