class PaymentController < ApplicationController
  include PaymentServices
  include ApplicationHelper

  before_action :authenticate_user!, :except => [:error, :detail, :update, :list_payment, :create]
  before_action :validate_course, :only => [:index, :cod, :card, :transfer, :cih, :online_payment, :pending, :payment_bill]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending, :import_code, :detail, :update]

  # GET
  def index
    cod_payments = Payment.where(
      :course_id => @course.id,
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::COD,
      :status.in => ['pending', 'process']
    ).to_a

    if cod_payments.size > 0
      redirect_to root_url + "/courses/#{@course.alias_name}/detail"
      return
    end

    coupon_code = params[:coupon_code]
    @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })

    @payment = Payment.new(
      course_id: @course.id,
      user_id: current_user.id,
      status: Constants::PaymentStatus::CREATED,
      money: @data[:final_price]
    )

    if @data[:final_price] == 0
      @payment.status = Constants::PaymentStatus::SUCCESS
      @payment.method = Constants::PaymentMethod::NONE
      @payment.coupons = [].push(@data[:coupon_code]) if @data[:coupon_code]
      
      unless @payment.save
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_method => Constants::PaymentMethod::NONE,
            :status => "fail"
          },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :identity => current_user.id.to_s,
          :object => payment.id
          )

        render 'page_not_found', status: 404
        return
      end
      create_course_for_user()

      owned_course = current_user.courses.where(course_id: @course.id).first
      owned_course.payment_status = Constants::PaymentStatus::SUCCESS
      owned_course.save

      redirect_to root_url + "/home/my-course/select_course?alias_name=#{@course.alias_name}&type=learning"
      return
    end
  end

  # GET, POST
  # Cash-on-delivery
  def cod
    cod_payments = Payment.where(
      :course_id => @course.id,
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::COD,
      :status.in => ['pending', 'process']
    ).to_a

    if cod_payments.size > 0
      redirect_to root_url + "/courses/#{@course.alias_name}/detail"
      return
    end

    coupon_code = params[:coupon_code]
    @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })

    if request.method == 'POST'
      payment = Payment.new(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::COD,
        :status => 'pending'
      )

      payment.coupons = @data[:coupon_code] ? [].push(@data[:coupon_code]) : []
      payment.name = params[:name]
      payment.email = params[:email]
      payment.mobile = params[:mobile]
      payment.address = params[:address]
      payment.city = params[:city]
      payment.district = params[:district]
      payment.money = @data[:final_price]

      # Create new COD
      cod_code = create_single_cod(@course.id, "pedia")
      payment.cod_code = cod_code if !cod_code.blank?

      if payment.save
        create_course_for_user()
        begin
          RestClient.post('http://flow.pedia.vn:8000/notify/cod/create',
            timeout: 2000,
            type: 'cod',
            payment: payment.as_json,
            msg: 'Có đơn COD cần xử lý'
          )
        rescue => e
        end
        utm_source = session[:utm_source].blank? ? {} : session[:utm_source]
        utm_source[:payment_id] = payment.id.to_s
        utm_source[:payment_method] = payment.method
        # Tracking L7c1
        Spymaster.params.cat('L7c1').beh('submit').tar(@course.id).user(current_user.id).ext(utm_source).track(request)
        redirect_to root_url + "/home/payment/#{payment.id.to_s}/pending?alias_name=#{@course.alias_name}"
      else
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_method => Constants::PaymentMethod::COD,
            :status => "fail"
          },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :identity => current_user.id.to_s,
          :object => payment.id
        )
        render 'page_not_found', status: 404
      end
    end
  end

  def cancel_cod
    payment = Payment.where(
      :course_id => params[:course_id],
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::COD
    ).or(
      {:status => "pending"},
      {:status => "process"}
    ).first

    unless payment.blank?
      payment.status = "cancel"
      payment.save
      owned_course = current_user.courses.where(course_id: params[:course_id]).first
      owned_course.payment_status = Constants::PaymentStatus::CANCEL
      owned_course.save

      # Tracking L7c3
      Spymaster.params.cat('L7c3').beh('submit').tar(owned_course.course_id).user(current_user.id).ext({:payment_id => payment.id,
          :payment_method => payment.method}).track(request)
    end

    redirect_to :back
  end

  # GET, POST
  def card
    if request.method == 'GET'
      process_card_payment()
    elsif request.method == 'POST'
      baokim = BaoKimPaymentCard.new

      receive_data = baokim.create_request_url({
        'transaction_id' => Time.now(),
        'card_id' => params[:card_id],
        'pin_field' => params[:pin_field],
        'seri_field' => params[:seri_field]
      })

      data = JSON.parse(receive_data.body)
      # check data 
      if data.blank?
        @error = "Lỗi nhà mạng. Xin vui lòng thử lại sau."
      end

      if receive_data.code == '200'
        current_user.money += data['amount'].to_i
        if current_user.save
          @error = "Bạn đã nạp thành công #{data['amount'].to_s}đ"
          # Tracking card deposit success
          Spymaster.params.cat('card_deposit').beh('success') \
            .user(current_user.id.to_s).tar(@course.id.to_s) \
            .ext({amount: data['amount'].to_i, pin: params[:pin_field], seri: params[:seri_field]}) \
            .track(request)
          process_card_payment()
        else
          Tracking.create_tracking(
            :type => Constants::TrackingTypes::PAYMENT,
            :content => {
              :payment_method => Constants::PaymentMethod::CARD,
              :status => "fail" },
            :ip => request.remote_ip,
            :platform => {},
            :device => {},
            :version => Constants::AppVersion::VER_1,
            :identity => current_user.id.to_s,
            :object => payment.id
          )
          # Tracking card deposit error from system
          Spymaster.params.cat('card_deposit').beh('fail') \
            .user(current_user.id.to_s).tar(@course.id.to_s) \
            .ext({reason: 'Could not save user', pin: params[:pin_field], seri: params[:seri_field]}) \
            .track(request)
          render 'page_not_found', status: 404
        end
      else
        coupon_code = params[:coupon_code]
        @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })
        @error = data['errorMessage']
        # Tracking card deposit failure from user or provider
        Spymaster.params.cat('card_deposit').beh('fail') \
          .user(current_user.id.to_s).tar(@course.id.to_s) \
          .ext({reason: @error, pin: params[:pin_field], seri: params[:seri_field]}) \
          .track(request)
      end
    end
  end

  # GET
  def transfer
    coupon_code = params[:coupon_code]
    @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })
  end

  # Cash-in-hand
  def cih
    coupon_code = params[:coupon_code]
    @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })
  end

  def online_payment

  end

  # GET
  def status
  end

  # GET
  def success
    baokim = BaoKimPaymentPro.new
    payment_service_provider = params[:p]
    @course = Course.where(id: @payment.course_id).first
    owned_course = current_user.courses.where(course_id: @course.id).first
    if payment_service_provider == 'baokim'
      if baokim.verify_response_url(params)
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS
        owned_course.save
      else
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_page => Constants::PaymentStatus::SUCCESS,
            :status => "fail",
            :baokim => "verify_response_url"
          },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :identity => current_user.id.to_s,
          :object => @payment.id
        )
        render 'page_not_found', status: 404
      end
    elsif payment_service_provider == 'baokim_card'
      @course = Course.where(id: @payment.course_id.to_s).first
    else
      @course = Course.where(id: @payment.course_id.to_s).first
    end

    if @payment
      # Tracking L8ga
      Spymaster.params.cat('L8ga').beh('open').tar(@course.id).user(current_user.id).ext({:payment_id => @payment.id,
          :payment_method => @payment.method}).track(request)
    end

    # If the first learning, display success page.
    owned_course.set(:first_learning => false) if !owned_course.blank?
  end

  # GET
  def cancel
    payment_service_provider = params[:p]
    if payment_service_provider == 'baokim'
      @course = Course.where(id: @payment.course_id).first
      
      owned_course = current_user.courses.where(course_id: @course.id).first
      owned_course.payment_status = Constants::PaymentStatus::CANCEL
      owned_course.save
    else
      @course = Course.last
    end
  end

  # GET
  def pending
  end

  # GET
  def error
  end

  # GET
  def payment_bill
    @payment = Payment.where(:course_id => @course.id, :user_id => current_user.id).first

    # render json: {:message => "Payment History"}
  end

  # POST
  # COD API
  def import_code
    cod_code = params[:cod_code]
    if @payment.cod_code == cod_code
      owned_course = current_user.courses.where(course_id: @payment.course_id.to_s).last
      owned_course.payment_status = Constants::PaymentStatus::SUCCESS
      @payment.status = Constants::PaymentStatus::SUCCESS
      @payment.save

      if owned_course.save
        render json: {message: "Thành công!"}
        return
      else
        render json: {message: "Có lỗi, vui lòng thử lại!"}, status: :missing
        return
      end
    else
      render json: {message: "Mã COD code không hợp lệ!"}, status: :missing
      return
    end    
  end

  # GET: API get cod payment for mercury
  def detail
    render json: PaymentSerializer.new(@payment).cod_hash
  end

  # POST: API update payment for mercury
  def update
    mobile = params[:mobile]
    email = params[:email]
    address = params[:address]
    status = params[:status]
    city = params[:city]
    district = params[:district]
    cod_code = params[:cod_code]

    @payment.update({
      mobile: mobile.blank? ? @payment.mobile : mobile,
      email: email.blank? ? @payment.email : email,
      address: address.blank? ? @payment.address : address,
      status: status.blank? ? @payment.status : status,
      city: city.blank? ? @payment.city : city,
      district: district.blank? ? @payment.district : district,
      cod_code: cod_code.blank? ? @payment.cod_code : cod_code
    })

    if (@payment.status == Constants::PaymentStatus::SUCCESS)
      render json: PaymentSerializer.new(@payment).cod_hash
      return
    end

    if @payment.save
      render json: PaymentSerializer.new(@payment).cod_hash
      return
    else
      render json: {message: "Lỗi không lưu được data! #{@payment.errors.as_json}"}
    end
  end

  # GET: API list payment for mercury
  def list_payment

    status = params[:status]
    method = params[:method]
    from = params[:from]
    to = params[:to]
    keywords = !params[:keyword].blank? ? params[:keyword] : '' 
    method = params[:method]
    payment_date = params[:date]
    page = params[:page].blank? ? 1 : params[:page].to_i
    per_page = params[:per_page] || 10

    condition = {}
    conditionName = {}
    conditionId = {}

    condition[:method] = method unless method.blank?
    condition[:status] = status unless status.blank?
    if !from.blank? && !to.blank?
      condition[:created_at] = from.to_date.beginning_of_day..to.to_date.end_of_day
      conditionName[:created_at] = from.to_date.beginning_of_day..to.to_date.end_of_day
      conditionId[:created_at] = from.to_date.beginning_of_day..to.to_date.end_of_day
    end

    condition[:created_at] = payment_date.to_date.beginning_of_day..payment_date.to_date.end_of_day unless payment_date.blank?
    
    conditionName[:method] = method unless method.blank?
    conditionName[:status] = status unless status.blank?
    conditionName[:name] = /#{Regexp.escape(keywords)}/i

    conditionId[:method] = method unless method.blank?
    conditionId[:status] = status unless status.blank?
    conditionId[:id] = keywords

    if !keywords.blank?
      payments = Payment.or(conditionName, conditionId).desc(:created_at)
    else 
      payments = Payment.where(condition).desc(:created_at)
    end

    total_pages = (payments.count.to_f / per_page).ceil
    next_page = page >= total_pages ? 0 : page + 1

    payments = payments.paginate(page: page, per_page: per_page).map { |payment|
      PaymentSerializer.new(payment).cod_hash
    }

    render json: {
      payments: payments,
      total_pages: total_pages,
      next_page: next_page
    }
    return
  end

  # POST: API create new payment
  def create
    user_id = params[:user_id]
    method  = params[:method]
    course_id = params[:course_id]
    coupon = params[:coupon]
    email = params[:email]
    address = params[:address]
    name = params[:name]
    mobile = params[:mobile]
    payment_status = (method == Constants::PaymentMethod::COD) ? Constants::PaymentStatus::PENDING : Constants::PaymentStatus::SUCCESS
    money = params[:money]
    cod_code = params[:cod_code]

    # Sử dụng cho combo courses.
    # Chuyển trạng thái payment từ pending sang cancel đối với những khoá thuộc combo. Và tạo 1 payment mới.
    is_combo_courses = params[:is_combo_courses]

    if (!is_combo_courses.blank? && method == Constants::PaymentMethod::COD) 
      payment = Payment.where(
        :course_id => course_id, 
        :user_id => user_id,
        :status.nin => [Constants::PaymentStatus::CANCEL]
      ).to_a.last
      unless payment.blank?
        if (payment.status == Constants::PaymentStatus::PENDING)
          payment.status = Constants::PaymentStatus::CANCEL
          payment.save
        end
      end
    end
    # =================================================

    payment = Payment.new(
      :user_id => user_id,
      :course_id => course_id,
      :method => method,
      :coupons => [coupon],
      :name => name,
      :email => email,
      :address => address,
      :mobile => mobile,
      :status => payment_status,
      :money => money,
      :cod_code => cod_code
    )

    user = User.find(user_id)
    course = Course.find(course_id)
    owned_course = user.courses.find_or_initialize_by(course_id: course_id)
    owned_course.created_at = Time.now() if owned_course.created_at.blank?

    # Create lecture for user
    course.curriculums.where(
      :type => Constants::CurriculumTypes::LECTURE
    ).map{ |curriculum|
      owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
    }

    if (payment.status == Constants::PaymentStatus::SUCCESS)
      total_student = course.students + 1
      course["students"] = total_student
    end
    
    owned_course.type = Constants::OwnedCourseTypes::LEARNING
    owned_course.payment_status = payment.status
    
    if payment.save && owned_course.save && user.save && course.save
      render json: PaymentSerializer.new(payment).cod_hash
      return
    else
      render json: {message: "Lỗi không lưu được data:"}, status: :unprocessable_entity
      return
    end
  end

  private
    def validate_payment
      payment_id = params[:id]
      @payment = Payment.where(:id => payment_id).first

      if @payment.blank?
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_validate => "Payment blank",
            :status => "fail",
          },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :identity => current_user.id.to_s,
          :object => @payment.id
        )
        render 'page_not_found', status: 404
        return
      end
    end

    def create_single_cod(course_id, issued_by = "pedia")
      # Create new COD
      uri = URI.parse('http://code.pedia.vn/cod/create_cod')
      cod_code = nil
      res = Net::HTTP.post_form uri, {
        :quantity => "1",
        :issued_by => issued_by,
        :course_id => course_id,
        :expired_date => (Time.now() + 1.years).strftime("%d/%m/%Y")
      }
      if (res.code.to_i == 200)
        res_json = JSON.parse(res.body)
        cod_code = res_json["cod_codes"].tr('^A-Za-z0-9', '')
      end
      return cod_code  
    end

    def create_course_for_user
      owned_course = current_user.courses.where(course_id: @course.id).first

      if owned_course.blank?
        owned_course = current_user.courses.create(course_id: @course.id, created_at: Time.now())
        UserGetCourseLog.create(course_id: @course.id, user_id: current_user.id, created_at: Time.now())
      end

      @course.curriculums
        .where(:type => Constants::CurriculumTypes::LECTURE)
        .map{ |curriculum|
          owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
        }

      total_student = @course.students + 1
      @course["students"] = total_student
    
      @course.save

      owned_course.type = Constants::OwnedCourseTypes::LEARNING
      owned_course.payment_status = Constants::PaymentStatus::PENDING

      owned_course.save
      current_user.save
    end

    def process_card_payment
      coupon_code = params[:coupon_code]
      @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })

      if current_user.money >= @data[:final_price]
        current_user.money -= @data[:final_price]
        create_course_for_user()

        payment = Payment.new(
          :course_id => @course.id,
          :user_id => current_user.id,
          :method => Constants::PaymentMethod::CARD,
          :created_at => Time.now(),
          :status => Constants::PaymentStatus::SUCCESS,
          :coupons => @data[:coupon_code] ? [].push(@data[:coupon_code]) : [],
          :money => @data[:final_price]
        )

        owned_course = current_user.courses.where(:course_id => @course.id.to_s).first
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS

        if (owned_course.save && payment.save && current_user.save)
          utm_source = session[:utm_source].blank? ? {} : session[:utm_source]
          utm_source[:payment_id] = payment.id
          utm_source[:payment_method] = payment.method
          # Tracking L7c1
          Spymaster.params.cat('L7c1').beh('submit').tar(@course.id).user(current_user.id).ext(utm_source).track(request)         
          redirect_to root_url + "home/payment/#{payment.id.to_s}/success?p=baokim_card"
          return
        else
          Tracking.create_tracking(
            :type => Constants::TrackingTypes::PAYMENT,
            :content => {
              :payment_method => Constants::PaymentMethod::CARD,
              :status => "fail",
              :owned_course_save => owned_course.errors,
              :payment_save => payment.errors,
              :current_user => current_user.errors
            },
            :ip => request.remote_ip,
            :platform => {},
            :device => {},
            :version => Constants::AppVersion::VER_1,
            :str_identity => current_user.id.to_s,
            :object => payment.id
          )
          render 'page_not_found', status: 404
          return
        end
      end
    end
end