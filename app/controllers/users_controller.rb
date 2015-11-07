class UsersController < ApplicationController

  before_action :set_user, :except => [:suggestion_search, :active_course, :get_user_detail, :create_instructor, :create, :reset_password, :forgot_password]
  before_filter :authenticate_user!, only: [:learning, :teaching, :wishlist, :select_course, :index, :update_wishlist, :get_notes, :create_note, :update_note, :delete_note]
  before_filter :validate_course, only: [:select_course]
  skip_before_filter :verify_authenticity_token, only: [:create_user_for_mercury]

  def index
    learning
  end

  def create

    # user = params[:user]
    # if !user.blank? && user.is_a?(Hash)
    #   user_new = User.new()
    #   user_new.id = user[:id] unless user[:id].blank?
    #   user_new.name = user[:name] unless user[:name].blank?
    #   user_new.email = user[:email] unless user[:email].blank?
    #   user_new.avatar = user[:avatar] unless user[:avatar].blank?
    #   user_new.password = user[:password].blank? ? '12345678' : user[:password]

    #   instructor_profile = {}
    #   if !user[:instructor_profile].blank? && user[:instructor_profile].is_a?(Hash)
    #     instructor_profile = user[:instructor_profile]
    #       .permit(:function, :academic_rank, :major, :work_unit, :description)
    #       .delete_if{|k, v| v.blank?}
    #   end
    #   user_new.instructor_profile = User::InstructorProfile.new(instructor_profile)

    #   if user_new.save
    #     render json: user_new.as_json
    #   else
    #     render json: {:error => user_new.errors}
    #   end
    # else
    #   render json: {:error => "Thiếu param user"}, status: :unprocessable_entity

    begin
      user = params[:user]

      if !user.blank?

        user_new = User.new()
        user_new.id = user[:id] unless user[:id].blank?
        user_new.name = user[:name] unless user[:name].blank?
        user_new.email = user[:email] unless user[:email].blank?
        user_new.avatar = user[:avatar] unless user[:avatar].blank?
        user_new.password = user[:password].blank? ? '12345678' : user[:password]

        instructor_profile = User::InstructorProfile.new()
        instructor_profile.description = user[:instructor_profile][:description] unless user[:instructor_profile][:description].blank?
        instructor_profile.major = user[:instructor_profile][:major] unless user[:instructor_profile][:major].blank?
        instructor_profile.function = user[:instructor_profile][:function] unless user[:instructor_profile][:function].blank?
        user_new.instructor_profile = instructor_profile

        if user_new.save
          render json: user_new.as_json
          return
        else
          render json: {:error => user_new.errors}
          return
        end
      else

      end
    rescue Exception => e
      render json: {:error => e.message}
    end
  end

  def create_user_for_mercury
    email = params[:email]
    name = params[:name]
    phone = params[:phone]
    password = params[:password].blank? ? '12345678' : params[:password]
    utm_source = params[:utm_source].blank? ? {} : JSON.parse(params[:utm_source])

    if email.blank?
      render json: {message: "Email is empty"}, status: :unprocessable_entity
      return
    end

    user = User.where(:email => email).first
    # Check exist email user
    if user
      render json: {user_id: user.id.to_s, :status => 'Exist email'}
      return
    end

    # Create user
    user = User.new()
    user.email = email unless email.blank?
    user.name = name unless name.blank?
    # user.mobile = phone unless phone.blank?
    user.password = password

    if user.save
      Spymaster.params.cat('U8').beh('submit').tar(user.id).user(user.id).ext(utm_source).track(request)
      render json: {user_id: user.id.to_s, :status => 'Create user'}
      return
    end

    render json: {message: "Can not save"}, status: :unprocessable_entity
    return
  end

  def hoc_thu
    if !current_user.blank?
      redirect_to "http://tuduylamchu.pedia.vn/hocthu.html"
      sign_out current_user
      return
    end
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

    @courses = []
    course_ids.each do |course_id|
      course = Course.where(:id => course_id).first
      @courses << course
    end
    @owned_courses = current_user.courses
    wishlist_ids = current_user.wishlist - course_ids.map(&:to_s)
    @wishlist = Course.in(:id => wishlist_ids).to_a

  end

  def teaching
    teaching = Constants::OwnedCourseTypes::TEACHING
    course_ids = current_user.courses.where(type: teaching).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def wishlist
    learning = Constants::OwnedCourseTypes::LEARNING
    course_ids = current_user.courses.where(
      :type => learning,
    ).map(&:course_id)
    # Wishlist inorge learned course.
    wishlist_ids = current_user.wishlist - course_ids.map(&:to_s)
    @owned_wishlist = Course.in(:id => wishlist_ids)
  end

  def update_wishlist
    course_id = params[:course_id]
    if course_id.blank?
      render json: {:message => "Course_id không có"}, status: :unprocessable_entity
      return
    end
    is_exist = current_user.wishlist.include?(course_id)

    if is_exist
      current_user.wishlist.delete(course_id)
    else
      current_user.wishlist << course_id
    end

    current_user.save

    render json: {:message => "ok"}
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
    expect_preview = params[:type] == "preview" # User wants to preview course
    # User wants to learn course
    expect_learning = ["learning", "learnning"].include? params[:type]
    # It should be
    # expect_learning = params[:type] == "learning"
    # But there is a mistake of naming, learnning instead of learning
    owned_course = current_user.courses.where(course_id: @course.id).first
    if owned_course # If user already has owned course
      # Check owned course type
      if owned_course.preview? # Preview course
        if expect_learning # If user wants to buy preview course
          redirect_to payment_url_for(@course, params)
        else # User want to preview course
          if owned_course.preview_expired?
            redirect_to root_url + "courses/#{@course.alias_name}/detail"
          else
            redirect_to root_url + "courses/#{@course.alias_name}/learning"
          end
        end
      else # Learning course
        # Check payment status
        if owned_course.payment_success? # Payment success then go to learning page
          redirect_to root_url + "courses/#{@course.alias_name}/learning"
          return
        else # Payment is not success then go to payment page
          redirect_to root_url + "courses/#{@course.alias_name}/detail"
        end
      end
    else # User hasn't had owned course yet
      # Check course price
      if @course.free? || expect_preview # If course is free or user wants to preview this course
        # We have to create owned course for the user
        # Set course status
        if expect_preview
          # Preview course should has no payment status
          payment_status = Constants::PaymentStatus::RESERVE
          type = Constants::OwnedCourseTypes::PREVIEW
          expired_at = Time.now + Constants::PreviewMode::TIME
        else
          payment_status = Constants::PaymentStatus::SUCCESS
          type = Constants::OwnedCourseTypes::LEARNING
          expired_at = nil
        end
        owned_course = current_user.courses.create(
          :course_id => @course.id,
          :created_at => Time.now(),
          :payment_status => payment_status,
          :type => type,
          :expired_at => expired_at)

        init_lectures_for_owned_course(owned_course, @course)

        UserGetCourseLog.create(course_id: @course.id, user_id: current_user.id, created_at: Time.now())
        if current_user.save
          # If course is preview then skip select page and go to learning page
          expect_preview ?
            (redirect_to root_url + "courses/#{@course.alias_name}/learning") :
            (redirect_to root_url + "courses/#{@course.alias_name}/select")
        else
          redirect_to root_url + "courses/#{@course.alias_name}/detail"
        end
      else # Course is not free and want to learn this course then
        # Just go to payment page
        redirect_to payment_url_for(@course, params)
      end
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

  # GET: API suggestion search for user by name
  def suggestion_search
    keywords = params[:q]
    keywords = Utils.nomalize_string(keywords)
    pattern = /#{Regexp.escape(keywords)}/

    users = User.or({:name => pattern}, {:email => pattern}).map { |user|
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

  # POST: API create instructor for kelley
  def create_instructor
    instructor = params["instructor"]

    if instructor.blank?
      render json: {message: "Chưa truyền dữ liệu!"}, status: :unprocessable_entity
      return
    end

    instructor = JSON.parse(instructor)

    user = User.new(
      name: instructor['name']
    )

    email = instructor['email'].blank? ? Utils.nomalize_string(instructor['name']).to_s + "@tudemy.vn" : instructor['email']
    user.email = email
    user.password = "12345678"

    instructor_profile = User::InstructorProfile.new()
    instructor_profile.academic_rank = instructor['instructor_profile']['academic_rank'] unless instructor['instructor_profile']['academic_rank'].blank?
    instructor_profile.major = instructor['instructor_profile']['major'] unless instructor['instructor_profile']['major'].blank?
    instructor_profile.function = instructor['instructor_profile']['function'] unless instructor['instructor_profile']['function'].blank?
    instructor_profile.work_unit = instructor['instructor_profile']['work_unit'] unless instructor['instructor_profile']['work_unit'].blank?
    instructor_profile.description = instructor['instructor_profile']['description'] unless instructor['instructor_profile']['description'].blank?

    user.instructor_profile = instructor_profile

    if user.save
      render json: {message: "Success"}
      return
    else
      render json: {message: "Lỗi không lưu được data"}, status: :unprocessable_entity
      return
    end
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

  def view_profile
    owned_course_ids = current_user.courses.map{|owned_course| owned_course.course_id.to_s}
    wishlist_ids = current_user.wishlist - owned_course_ids

    @owned_courses = current_user.courses.in(:course_id => owned_course_ids).to_a
    @owned_wishlist = Course.in(:id => wishlist_ids).to_a
  end

  # GET /users/edit_profile
  def edit_profile
    @user = User.find(current_user.id)
    if request.patch?
      profile_params = user_profile_params
      profile_params[:lang] = Constants::UserLang::VI if profile_params[:lang].blank?
      profile_params[:name] = profile_params[:first_name] + " " + profile_params[:last_name]
      profile_params[:links].each do |key, value|
        if !value.blank?
          profile_params[:links][key].insert(0, Constants::PROFILE_LINK_PREFIX[key.to_sym])
        end
      end
      if @user.update(profile_params)
        flash.now[:sucess_changing_profile] = "Cập nhật thông tin thành công"
      else
        flash.now[:error_changing_profile] = "Thông tin chưa được cập nhật, vui lòng thử lại"
      end
    end
  end

  # GET /users/edit_account
  def edit_account
    if request.patch?
      info = change_password_params
      if info[:current_password].blank? || info[:password].blank? || info[:password_confirmation].blank?
        flash.now[:error_changing_password] = "Thông tin không đầy đủ"
      else
        @user = User.find(current_user.id)
        if @user.update_with_password(info)
          # Sign in the user by passing validation in case their password changed
          sign_in @user, :bypass => true
          flash.now[:success_changing_password] = "Đổi mật khẩu thành công"
        else
          messages = @user.errors.messages
          if messages.include?(:current_password)
            flash.now[:error_changing_password] = "Mật khẩu hiện tại không đúng"
          elsif messages.include?(:password_confirmation)
            flash.now[:error_changing_password] = "Xác nhận mật khẩu không đúng"
          else
            flash.now[:error_changing_password] = "Không thể thay đổi mật khẩu của bạn, vui lòng thử lại"
          end
        end
      end
    end
  end


  # /users/request_reset_password?email=sfdsfsf
  def forgot_password
    # Check email
    email = params[:email]
    @user = User.where(:email => email).first
    if not @user
      render json: {message: "Email không tồn tại, vui lòng kiểm tra lại"}, status: 402
      return
    end

    # Generate reset password token & expired time
    @user.reset_password_token = new_reset_password_token(email)
    @user.reset_password_sent_at = Time.now
    @user.save

    link = "https://pedia.vn/users/reset_password?token=#{@user.reset_password_token}"
    # Send email
    RestClient.post('http://email.pedia.vn/email_services/send_email',
      email: email,
      str_html: "<div style='background: #fff;font: 14px sans-serif;color: #737373;border-top: 4px solid #17aa1c;margin-bottom: 20px;font-family: arial,sans-serif'> <div class='header' style='border-bottom: 1px solid #f4f4f4;padding-bottom: 20px;padding-left: 30px;padding-top: 20px;display: block'> <img src='http://i.imgur.com/GminBIY.png' style='width: 150px;display: block;max-width: 100%;' /> </div> <div class='content' style='padding: 30px 20px;line-height: 1.5em;color: #737373;;display: block'> <p>Xin chào " + @user.name + "</p> <p style='border-bottom:1px solid #f4f4f4;padding-bottom:20px;margin-bottom:20px;color:#737373'>Nhấn vào nút bên dưới để thay đổi mật khẩu của bạn.</p> <a href='" + link + "' style='display:inline-block;font-size:15px;color:#ffffff;padding:10px 15px;text-decoration:none;background-color:#1376d7;border-radius:3px' target='_blank'>Thay đổi mật khẩu của bạn</a> </div> </div>",
      sender: 'Pedia<mecury@pedia.vn>',
      subj: 'Đặt lại mật khẩu Pedia'
    )

    render json: {message: "Vui lòng kiểm tra email để tiếp tục"}, status: 200
  end

  def new_reset_password_token(email)
    Digest::SHA1.hexdigest([Time.now, rand, email].join)
  end

  def reset_password
    token = params[:token]
    if token.blank?
      render 'invalid_reset_request'
      return
    end
    @user = User.where(:reset_password_token => token).first
    if not @user
      render 'invalid_reset_request'
      return
    end
    valid = @user.reset_password_sent_at >= Time.now - 30.minutes
    if not valid
      render 'invalid_reset_request'
      return
    end

    if request.patch?
      info = reset_password_params
      if info[:password].blank? || info[:password_confirmation].blank?
        flash.now[:error_changing_password] = "Thông tin không đầy đủ"
      else
        if @user.update(info)
          # Sign in the user by passing validation in case their password changed
          flash.now[:success_changing_password] = "Đổi mật khẩu thành công"
          redirect_to "/"
          return
        else
          messages = @user.errors.messages
          if messages.include?(:password_confirmation)
            flash.now[:error_changing_password] = "Xác nhận mật khẩu không đúng"
          else
            flash.now[:error_changing_password] = "Không thể thay đổi mật khẩu của bạn, vui lòng thử lại"
          end
        end
      end
    end
  end

  def edit_avatar
    if request.patch? && params[:user] && params[:user][:new_avatar]
      begin
        file_io = params[:user][:new_avatar]
        timestamp = Time.now.to_i
        file_name = file_io.original_filename
        file_name = file_name.sub(/\.(?=[^.]*$)/, "-#{timestamp}.")
        path = Rails.public_path.join("avatars")
        path.mkpath unless path.exist?
        File.open(path.join(file_name), 'wb') do |file|
          file.write(file_io.read)
          @user.avatar = "/avatars/" + file_name
          @user.save
          flash.now[:success_changing_avatar] = "Thay đổi avatar thành công"
        end
      rescue
        flash.now[:error_changing_avatar] = "Ảnh đại diện chưa cập nhật được, vui lòng thử lại"
      end
    end
  end

  def create_note
    owned_course_id = params[:owned_course_id]
    owned_lecture_id = params[:owned_lecture_id]
    time = params[:time].blank? ? "00:00" : params[:time]
    content = params[:content]

    if content.blank?
      render json: {:message => 'Note không có nội dung.'}, status: :unprocessable_entity
      return
    end

    course = nil
    lecture = nil
    course = current_user.courses.where(:id => owned_course_id).first if !owned_course_id.blank?
    lecture = course.lectures.where(:id => owned_lecture_id).first if !course.blank?
    if (course && lecture)
      note = lecture.notes.create(:time => time, :content => content)
      render json: User::NoteSerializer.new(note)
      return
    end
    render json: {:message => 'Tạo note thất bại.'}, status: :unprocessable_entity
  end

  def get_notes
    owned_course_id = params[:owned_course_id]
    owned_lecture_id = params[:owned_lecture_id]

    if (owned_course_id.blank? || owned_lecture_id.blank?)
      render json: {:message => 'Thiếu tham số truyền lên.'}, status: :unprocessable_entity
      return
    end

    course = nil
    lecture = nil
    course = current_user.courses.where(:id => owned_course_id).first if !owned_course_id.blank?
    lecture = course.lectures.where(:id => owned_lecture_id).first if !course.blank?

    if course && lecture
      notes = []
      lecture.notes.desc(:created_at).each{ |note|
        notes << User::NoteSerializer.new(note)
      }
      render json: {:notes => notes}
      return
    end
    render json: {message: 'Không get được notes'}, status: :unprocessable_entity
  end

  def update_note
    owned_course_id = params[:owned_course_id]
    owned_lecture_id = params[:owned_lecture_id]
    note_id = params[:note_id]
    content = params[:content]

    course = nil
    lecture = nil
    course = current_user.courses.where(:id => owned_course_id).first if !owned_course_id.blank?
    lecture = course.lectures.where(:id => owned_lecture_id).first if !course.blank?

    if course && lecture
      note = lecture.notes.where(:id => note_id).first
      note.content = content if ( !content.blank? && !note.blank? )
      if note.save
        render json: User::NoteSerializer.new(note)
        return
      end
    end
    render json:{:message => 'Update note thất bại'}, status: :unprocessable_entity
  end

  def delete_note
    owned_course_id = params[:owned_course_id]
    owned_lecture_id = params[:owned_lecture_id]
    note_id = params[:note_id]
    content = params[:content]

    course = nil
    lecture = nil
    course = current_user.courses.where(:id => owned_course_id).first if !owned_course_id.blank?
    lecture = course.lectures.where(:id => owned_lecture_id).first if !course.blank?
    if course && lecture
      note = lecture.notes.where(:id => note_id).first
      if (!note.blank? ? note.delete : false)
        render json:{:message => 'Xoá note thành công'}
        return
      end
    end
    render json:{:message => 'Xoá note thất bại'}, status: :unprocessable_entity
  end

  def download_note
    owned_course_id = params[:owned_course_id]
    owned_lecture_id = params[:owned_lecture_id]
    if owned_course_id && owned_lecture_id
      owned_course = current_user.courses.where(:id => owned_course_id).first
      if owned_course
        owned_lecture = owned_course.lectures.where(:id => owned_lecture_id).first
        if owned_lecture
          lt = owned_course.course.curriculums.where(:lecture_index => owned_lecture.lecture_index).first
          csv_content = CSV.generate do |csv|
            csv.add_row ['Time', 'Note']
            owned_lecture.notes.each do |note|
              values = [note.time, note.content]
              csv.add_row values
            end
          end
          send_data csv_content, :filename => "#{lt.title} - Ghi chú.csv"
          return
        end
      end
    end
    render text: 'File note found', status: 404
  end
  # GET
  def payment_history
    owned_payments = Payment.where(:user_id => current_user.id, :course_id.ne => nil).to_a
    @courses = []
    @payments = []
    owned_payments.each do |payment|
      course = Course.where(:id => payment.course_id).first
      if !course.blank?
        @payments << payment
        @courses << course
      end
    end
    # render json: {:message => "Payment History"}
  end

  # Get : API for mercury
  def get_course_of_instructor
    instructor_id = params[:instructor_id]

    course_ids = if instructor_id.blank?
      []
    else
      Course.where(:user_id => instructor_id).map(&:id).map(&:to_s)
    end

    render json: {:course_ids => course_ids}
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

    def user_profile_params
      accessible = [:desination, :first_name, :last_name, :job, :biography, :lang, links: [ :website, :google, :facebook, :linkedin, :twitter, :youtube]]
      params.require(:user).permit(accessible)
    end

    def change_password_params
      params.require(:user).permit(['current_password', 'password', 'password_confirmation'])
    end

    def reset_password_params
      params.require(:user).permit(['password', 'password_confirmation'])
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

    def payment_url_for(course, params)
      url = root_url + "home/payment/#{course.alias_name}"
      if !params.blank?
        url += "?coupon_code=#{params['coupon_code']}" if !params['coupon_code'].blank?
      end
      return url
    end
end