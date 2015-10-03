class PaymentController < ApplicationController
  include PaymentServices

  before_filter :authenticate_user!, :except => [:error, :detail, :update, :list_payment, :create]
  before_action :validate_course, :except => [:status, :success, :cancel, :error, :import_code, :cancel_cod, :detail, :update, :list_payment, :create]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending, :import_code, :detail, :update]
  # before_action :process_coupon, :except => [:status, :success, :cancel, :error, :import_code, :cancel_cod, :detail, :update, :list_payment, :create]
  # GET
  def index
    cod_payments = Payment.where(
      :course_id => @course.id,
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::COD
    ).or(
      {:status => "pending"},
      {:status => "process"}
    ).all.to_a

    if cod_payments.size > 0
      redirect_to :back
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
    coupon_code = params[:coupon_code]
    @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })

    if request.method == 'POST'
      payment = Payment.find_or_initialize_by(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::COD
      )

      payment.coupons = @data[:coupon_code] ? [].push(@data[:coupon_code]) : []
      payment.name = params[:name]
      payment.email = params[:email]
      payment.mobile = params[:mobile]
      payment.address = params[:address]
      payment.city = params[:city]
      payment.district = params[:district]
      payment.money = @data[:final_price]

      if payment.save
        create_course_for_user()
        begin
          RestClient.post 'http://flow.pedia.vn:8000/notify/cod/create', :timeout => 2000, :type => 'cod', :payment => payment.as_json, :msg => 'Có đơn COD cần xử lý '
          # RestClient.post('http://internal.tudemy.vn:8000/notify',
          #   {
          #     :to => 'mercury',
          #     :msg => "{type:'cod', msg: 'Có đơn COD mới'}"
          #   }
          # )
        rescue => e
        end

        # Tracking L7c1
        params = {
          Constants::TrackingParams::CATEGORY => "L7c1",
          Constants::TrackingParams::TARGET => @course.id,
          Constants::TrackingParams::BEHAVIOR => "submit",
          Constants::TrackingParams::USER => current_user.id,
          Constants::TrackingParams::EXTRAS => {
            :chanel => (request.params['utm_source'].blank? ? request.referer : request.params['utm_source']),
            :payment_id => payment.id,
            :payment_method => payment.method,
            :payment_status => payment.status
          }
        }
        Spymaster.track(params, request.blank? ? nil : request)

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
      params = {
        Constants::TrackingParams::CATEGORY => "L7c3",
        Constants::TrackingParams::TARGET => owned_course.course_id,
        Constants::TrackingParams::BEHAVIOR => "submit",
        Constants::TrackingParams::USER => current_user.id,
        Constants::TrackingParams::EXTRAS => {
          :payment_id => payment.id,
          :payment_method => payment.method
        }
      }
      Spymaster.track(params, request.blank? ? nil : request)
    end

    redirect_to :back
  end

  # GET, POST
  def card
    if request.method == 'GET'
      process_card_payment()
    elsif request.method == 'POST'
      create_course_for_user()
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

          render 'page_not_found', status: 404
        end
      else
        coupon_code = params[:coupon_code]
        @data = Sale::Services.get_price({ course: @course, coupon_code: coupon_code })
        @error = data['errorMessage']
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
    # Tracking U8p
    if current_user.courses.count == 1
      params = {
        Constants::TrackingParams::CATEGORY => "U8p",
        Constants::TrackingParams::TARGET => @course.id,
        Constants::TrackingParams::BEHAVIOR => "click",
        Constants::TrackingParams::USER => current_user.id,
        Constants::TrackingParams::EXTRAS => {
          :payment_id => @payment.id
        }
      }
      Spymaster.track(params, request.blank? ? nil : request)
    elsif current_user.courses.count > 1
      # Tracking U8fp
      payments_count = Payment.where(:user_id => current_user.id, :status => Constants::PaymentStatus::SUCCESS).count
      if payments_count == 1
        params = {
          Constants::TrackingParams::CATEGORY => "U8fp",
          Constants::TrackingParams::TARGET => @course.id,
          Constants::TrackingParams::BEHAVIOR => "click",
          Constants::TrackingParams::USER => current_user.id,
          Constants::TrackingParams::EXTRAS => {
            :payment_id => @payment.id
          }
        }
        Spymaster.track(params, request.blank? ? nil : request)         
      end
    end

    # Tracking L8ga
    if @payment
      params = {
        Constants::TrackingParams::CATEGORY => "L8ga",
        Constants::TrackingParams::TARGET => @course.id,
        Constants::TrackingParams::BEHAVIOR => "open",
        Constants::TrackingParams::USER => current_user.id,
        Constants::TrackingParams::EXTRAS => {
          :payment_id => @payment.id,
          :payment_method => @payment.method
        }
      }
      Spymaster.track(params, request.blank? ? nil : request)
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

    @payment.update({
      mobile: mobile.blank? ? @payment.mobile : mobile,
      email: email.blank? ? @payment.email : email,
      address: address.blank? ? @payment.address : address,
      status: status.blank? ? @payment.status : status
    })

    if @payment.save
      render json: PaymentSerializer.new(@payment).cod_hash
      return
    else
      render json: {message: "Lỗi không lưu được data!"}
    end
  end

  # GET: API list payment for mercury
  def list_payment
    name = params[:name]
    method = params[:method]
    payment_date = params[:date]
    page = params[:page].to_i || 1
    per_page = params[:per_page] || 10

    condition = {}
    condition[:name] = /#{Regexp.escape(name)}/ unless name.blank?
    condition[:method] = method unless method.blank?
    condition[:created_at] = payment_date.to_date.beginning_of_day..payment_date.to_date.end_of_day unless payment_date.blank?
    
    payments = Payment.where(condition).desc(:created_at)

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

    payment = Payment.new(
      :user_id => user_id,
      :course_id => course_id,
      :method => method,
      :coupons => [coupon],
      :name => name,
      :email => email,
      :address => address,
      :mobile => mobile,
      :status => 'success'
    )

    user = User.find(user_id)
    course = Course.find(course_id)
    owned_course = user.courses.find_or_initialize_by(course_id: course_id)
    owned_course.created_at = Time.now() if owned_course.created_at.blank?

    course.curriculums.where(
      :type => Constants::CurriculumTypes::LECTURE
    ).map{ |curriculum|
      owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
    }

    total_student = course.students + 1
    course["students"] = total_student
    
    owned_course.type = Constants::OwnedCourseTypes::LEARNING
    owned_course.payment_status = Constants::PaymentStatus::SUCCESS

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

        # NOTE: Online payment is disabled
        # Update all previous online payment(s) of the user, who has the course
        # Payment.where(:method => 'online_payment', user_id: current_user.id, course_id: @course.id)
        #        .update_all(status: "cancel")

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

        # NOTE: bad cod
        if (owned_course.save && payment.save && current_user.save)
          # Tracking L7c1
          params = {
            Constants::TrackingParams::CATEGORY => "L7c1",
            Constants::TrackingParams::TARGET => @course.id,
            Constants::TrackingParams::BEHAVIOR => "submit",
            Constants::TrackingParams::USER => current_user.id,
            Constants::TrackingParams::EXTRAS => {
              :chanel => (request.params['utm_source'].blank? ? request.referer : request.params['utm_source']),
              :payment_id => payment.id,
              :payment_method => payment.method,
              :payment_status => payment.status
            }
          }
          Spymaster.track(params, request.blank? ? nil : request)          
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

    def get_discount_coupon(coupon_code)
      if coupon_code
        url = URI.parse("http://code.pedia.vn/coupon?coupon=#{@coupon_code}")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)
          http.request(req)
        }
        if res.code.to_i == 200
          res_body = JSON.parse(res.body)
          return res_body['discount'].to_i
        end
      end
      return 0
    end
end