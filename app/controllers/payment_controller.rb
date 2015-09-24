class PaymentController < ApplicationController
  include PaymentServices

  before_filter :authenticate_user!, :except => [:error, :detail, :update, :list_payment, :create]
  before_action :validate_course, :except => [:status, :success, :cancel, :error, :import_code, :cancel_cod, :detail, :update, :list_payment, :create]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending, :import_code, :update]
  before_action :process_coupon, :except => [:status, :success, :cancel, :error, :import_code, :cancel_cod, :detail, :update, :list_payment, :create]
  before_action :cancel_payment_logic, :only => [:cod, :online_payment, :card]

  # GET
  def index
    payment = Payment.where(
      :course_id => @course.id,
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::COD
    ).or(
      {:status => "pending"},
      {:status => "process"}
    ).first

    unless payment.blank?
      redirect_to :back
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

      redirect_to :back
    else
      redirect_to :back
    end
  end

  # GET, POST
  # Cash-on-delivery
  def cod
    if request.method == 'POST'
      name = params[:name]
      email = params[:email]
      mobile = params[:mobile]
      address = params[:address]
      city = params[:city]
      district = params[:district]

      payment = Payment.new(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::COD,
        :coupons => @coupons,
        :money => @price,
        :name => name,
        :email => email,
        :mobile => mobile,
        :address => address,
        :city => city,
        :district => district 
      ) 

      if payment.save
        create_course_for_user()
        begin
          payment['course_name'] = @course.name
          RestClient.post 'http://flow.pedia.vn:8000/notify/cod/create', :timeout => 2000, :type => 'cod', :payment => payment.as_json, :msg => 'Có đơn COD cần xử lý ' 
        rescue Exception => e
        end
        redirect_to root_url + "/home/payment/#{payment.id.to_s}/pending?alias_name=#{@course.alias_name}"
      else
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_method => Constants::PaymentMethod::COD,
            :status => "fail" },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :str_identity => current_user.id.to_s,
          :object => payment.id
        )
        render 'page_not_found', status: 404
      end
    end

    @coupon_code = params[:coupon_code]
  end

  def online_payment
    baokim = BaoKimPaymentPro.new
    payment_service_provider = params[:p]

    # if request.method == 'GET'
    banks = baokim.get_seller_info()
    @local_card_banks = banks.select{|x| x["payment_method_type"] == PaymentServices::BaoKimConstant::PAYMENT_METHOD_TYPE_LOCAL_CARD}
    @credit_cards = banks.select{|x| x["payment_method_type"] == PaymentServices::BaoKimConstant::PAYMENT_METHOD_TYPE_CREDIT_CARD}
    if request.method == 'POST'
      payment = Payment.new(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::ONLINE_PAYMENT
      )

      if payment.save
        create_course_for_user()
      else
        Tracking.create_tracking(
          :type => Constants::TrackingTypes::PAYMENT,
          :content => {
            :payment_method => Constants::PaymentMethod::ONLINE_PAYMENT,
            :status => "fail" },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :str_identity => current_user.id.to_s,
          :object => payment.id
        )
        render 'page_not_found', status: 404
      end

      if payment_service_provider == 'baokim'
        payment.coupons = @coupons
        payment.money = @price
        payment.name = params['payer_name']
        payment.email = params['payer_email']
        payment.address = params['payer_address']
        payment.mobile = params['payer_phone_no']

        payment.save

        result = baokim.pay_by_card({
          'order_id' =>  payment.id.to_s,
          'bank_payment_method_id' => params['bank_payment_method_id'].to_i,
          'currency_code' => 'VND',
          'transaction_mode_id' => '1',
          'escrow_timeout' => 3,
          'total_amount' => @price,
          'shipping_fee' =>  0,
          'tax_fee' =>  0,
          'order_description' =>  @course.name,
          'url_success' =>  request.protocol + request.host_with_port + '/home/payment/' + payment.id + '/success?p=baokim',
          'url_cancel' =>  request.protocol + request.host_with_port + '/home/payment/' + payment.id + '/cancel?p=baokim',
          'url_detail' =>  request.protocol + request.host_with_port + '/courses/' + @course.alias_name + '/detail',
          'payer_name' => params['payer_name'],
          'payer_email' => params['payer_email'],
          'payer_phone_no' => params['payer_phone_no'],
          'payer_address' => params['address']
        })
        redirect_to result['redirect_url'] if result['error'].blank?
      end
    end
  end

  # GET, POST
  def card
    if request.method == 'GET'
      process_card_payment
    elsif request.method == 'POST'
      card_id = params[:card_id]
      pin_field = params[:pin_field]
      seri_field = params[:seri_field]
      time_payment = Time.now()
      create_course_for_user()
      baokim = BaoKimPaymentCard.new

      revice_data = baokim.create_request_url({
        'transaction_id' => time_payment,
        'card_id' => card_id,
        'pin_field' => pin_field,
        'seri_field' => seri_field
      })

      data = JSON.parse(revice_data.body)
      # check data 
      if data.blank?
        @error = "Lỗi nhà mạng. Xin vui lòng thử lại sau."
      end

      if revice_data.code.to_i == 200
        current_user.money += data['amount'].to_i
        if current_user.save
          @error = "Bạn đã nạp thành công " + data['amount'].to_s + "đ"
          process_card_payment
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
          :str_identity => current_user.id.to_s,
          :object => payment.id
        )
          render 'page_not_found', status: 404
        end
      else
        @error = data['errorMessage']
        # url = request.protocol + request.host_with_port + "/home/payment/card/#{params[:alias_name]}?p=baokim_card"
        # url += "&coupon_code=#{params[:coupon_code]}" unless params[:coupon_code].blank?
        # redirect_to url
      end
    end
  end

  # GET
  def transfer
  end

  # Cash-in-hand
  def cih
  end

  # GET
  def status
  end

  # GET
  def success
    payment_service_provider = params[:p]
    if payment_service_provider == 'baokim'
      baokim = BaoKimPaymentPro.new
      @course = Course.where(id: @payment.course_id).first
      if baokim.verify_response_url(params)
        owned_course = current_user.courses.where(course_id: @course.id).first
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
          :str_identity => current_user.id.to_s,
          :object => payment.id
        )
        render 'page_not_found', status: 404
      end
    elsif payment_service_provider == 'baokim_card'
      @course = Course.where(id: @payment.course_id.to_s).first
    end
  end

  # GET
  def cancel
    payment_service_provider = params[:p]
    if payment_service_provider == 'baokim'
      @course = Course.where(id: @payment.course_id).first
      
      owned_course = current_user.courses.where(course_id: @course.id).first
      owned_course.payment_status = Constants::PaymentStatus::CANCEL
      owned_course.save
    end
  end

  # GET
  def pending
  end

  # GET
  def error
  end

  # POST
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
        render json: {message: "Có lỗi, vui lòng thử lại!"}, status: :unprocessable_entity
        return
      end
    else
      render json: {message: "Mã COD code không hợp lệ!"}, status: :unprocessable_entity
      return
    end    
  end

  # GET: API get cod payment for mercury
  def detail
    payment_id = params[:id]
    @payment = Payment.where(:id => payment_id).first
    if @payment
      render json: PaymentSerializer.new(@payment).cod_hash
    else 
      render json: {message: "Payment không tồn tại!"}
    end
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
    money = params[:money]

    payment = Payment.new(
      :user_id => user_id,
      :course_id => course_id,
      :method => method,
      :coupons => [coupon],
      :name => name,
      :email => email,
      :address => address,
      :mobile => mobile,
      :status => "success",
      :money => money
    )

    user = User.where(id: user_id).first
    course = Course.where(id: course_id).first

    if course.blank? || user.blank?
      Tracking.create_tracking(
        :type => Constants::TrackingTypes::PAYMENT,
        :content => {
          :message => "user_id hoặc course_id truyền lên không đúng!",
          :status => "fail" },
        :ip => request.remote_ip,
        :platform => {},
        :device => {},
        :version => Constants::AppVersion::VER_1,
        :str_identity => user_id.to_s
      )

      render json: {message: "user_id hoặc course_id truyền lên không đúng!"}, status: :unprocessable_entity
      return
    end

    owned_course = user.courses.find_or_initialize_by(course_id: course_id)
    owned_course.created_at = Time.now() if owned_course.created_at.blank?
    course.curriculums.where(
      :type => Constants::CurriculumTypes::LECTURE
    ).map{ |curriculum|
      owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
    }

    course.students += 1
    
    owned_course.type = Constants::OwnedCourseTypes::LEARNING
    owned_course.payment_status = Constants::PaymentStatus::SUCCESS

    if payment.save && owned_course.save && user.save && course.save
      render json: PaymentSerializer.new(payment).cod_hash
      return
    else
      Tracking.create_tracking(
        :type => Constants::TrackingTypes::PAYMENT,
        :content => {
          :message => payment.errors.full_messages.join(", "),
          :status => "fail" },
        :ip => request.remote_ip,
        :platform => {},
        :device => {},
        :version => Constants::AppVersion::VER_1,
        :str_identity => user_id.to_s
      )

      render json: {message: payment.errors.full_messages.join(", ")}, status: :unprocessable_entity
      return
    end
  end

  private
    def cancel_payment
      Payment.where(:user_id => current_user.id, course_id: @course.id).update_all(status: "cancel")
    end

    def cancel_payment_logic
      if request.method == "POST"
        cancel_payment
      end
    end

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
          :str_identity => current_user.id.to_s,
          :object => payment.id
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

      @course.students += 1
      @course.save

      owned_course.type = Constants::OwnedCourseTypes::LEARNING
      owned_course.payment_status = Constants::PaymentStatus::PENDING

      owned_course.save
      current_user.save
    end

    def process_card_payment
      if current_user.money > @price
        
        current_user.money -= @price
        create_course_for_user()
        # Chuyển trạng thái những thằng payment của (course + user) trước sang fail
        Payment.where(:method => 'online_payment', user_id: current_user.id, course_id: @course.id).update_all(status: "cancel")
      
        payment = Payment.new(
          :course_id => @course.id,
          :user_id => current_user.id,
          :method => Constants::PaymentMethod::CARD,
          :created_at => Time.now(),
          :status => Constants::PaymentStatus::SUCCESS,
          :coupons => @coupons,
          :money => @price
        )

        owned_course = current_user.courses.where(:course_id => @course.id.to_s).first
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS

        if (owned_course.save && payment.save && current_user.save)
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

    def process_coupon
      @coupon_code = params['coupon_code']
      @discount = 0
      @coupons = []
      if !@coupon_code.blank?
        @coupon_code.split(",").each {|coupon|
          uri = URI("http://code.pedia.vn/coupon?coupon=#{coupon}")
          response = Net::HTTP.get(uri)
          if JSON.parse(response)['return_value'].to_i > 0
            @discount += JSON.parse(response)['return_value'].to_f
            @coupons << coupon
          end
        }
      end
      @price = ((@course.price * (100 - @discount) / 100) / 1000).to_i * 1000
    end
end