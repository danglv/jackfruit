class UsersController < ApplicationController

  # before_filter :authenticate_user!

  def index
    binding.pry
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

  def login_with_email

  end

  def login_with_facebook
    
  end

  def login_with_google
    
  end

  def logout

  end

  def edit_profile
    
  end

  def upload_avatar
    
  end

  def learning
    learning = Constants::OwnedCourseTypes::LEARNING
    # course_ids = @current_user.courses.where(type: learning).map(&:course_id)
    # @courses = Course.where(:id.in => course_ids)

  end

  def teaching
    teaching = Constants::OwnedCourseTypes::TEACHING
    course_ids = @current_user.courses.where(type: teaching).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def wishlist
    wishlist = Constants::OwnedCourseTypes::WISHLIST
    course_ids = @current_user.courses.where(type: wishlist).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def search
    keywords = params[:q]
    pattern = /#{Regexp.escape(keywords)}/
    @courses = []
    @current_user.courses.map{|owned_course|
      @courses << owned_course.course if (owned_course.course.name =~ pattern) == 0
    }

    head :ok
  end

  def select_course
    course_id = params[:course_id]
    owned_course = @current_user.courses.create(
      type: Constants::OwnedCourseTypes::LEARNING,
      course_id: course_id
    )
    init_lectures_for_owned_course(owned_course, course_id)
    @current_user.save

    head :ok
  end

  private
    def init_lectures_for_owned_course(owned_course, course_id)
      course = Course.where(id:course_id).first
      course.curriculums.where(
        :type => Constants::CurriculumTypes::LECTURE
      ).map{|curriculum|
        owned_course.lectures.create(:lecture_index => curriculum.lecture_index)
      }

      course.set(:students => course.students + 1)
    end

    def check_valid_length(string, min_length, max_length)
      string.length >= min_length && string.length <= max_length
    end
end