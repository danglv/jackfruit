class PaymentController < ApplicationController
  include PaymentServices

  before_filter :authenticate_user!, :except => [:error]
  before_action :validate_course, :except => [:status, :success, :cancel, :error, :import_code, :cancel_cod]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending, :import_code]

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

      payment = Payment.find_or_initialize_by(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::COD
      )

      payment.name = name,
      payment.email = email,
      payment.mobile = mobile,
      payment.address = address,
      payment.city = city,
      payment.district = district,

      if payment.save
        create_course_for_user()
        redirect_to root_url + "/home/payment/#{payment.id.to_s}/pending?alias_name=#{@course.alias_name}"
      else
        render 'page_not_found', status: 404
      end
    end
  end

  def online_payment
    baokim = BaoKimPaymentPro.new
    payment_service_provider = params[:p]

    if request.method == 'GET'
      banks = baokim.get_seller_info()
      @local_card_banks = banks.select{|x| x["payment_method_type"] == PaymentServices::BaoKimConstant::PAYMENT_METHOD_TYPE_LOCAL_CARD}
      @credit_cards = banks.select{|x| x["payment_method_type"] == PaymentServices::BaoKimConstant::PAYMENT_METHOD_TYPE_CREDIT_CARD}
    elsif request.method == 'POST'
      # Chuyển trạng thái những thằng payment của (course + user) trước sang fail
      Payment.where(:method => 'online_payment', user_id: current_user.id, course_id: @course.id).update_all(status: "cancel")
      
      payment = Payment.new(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::ONLINE_PAYMENT
      )

      if payment.save
        create_course_for_user()
      else
        render 'page_not_found', status: 404
      end

      if payment_service_provider == 'baokim'

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
          'total_amount' =>  @course.price,
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
          render 'page_not_found', status: 404
        end
      else
        @error = data['errorMessage']
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
      @course = Course.where(id: @payment.course_id).first
      if baokim.verify_response_url(params)
        owned_course = current_user.courses.where(course_id: @course.id).first
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS
        owned_course.save
      else
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
        render json: {message: "Có lỗi, vui lòng thử lại!"}, status: :missing
        return
      end
    else
      render json: {message: "Mã COD code không hợp lệ!"}, status: :missing
      return
    end    
  end

  private
    def validate_payment
      payment_id = params[:id]
      @payment = Payment.where(:id => payment_id).first

      if @payment.blank?
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
      if current_user.money > @course.price
        current_user.money -= @course.price

        create_course_for_user()
        # Chuyển trạng thái những thằng payment của (course + user) trước sang fail
        Payment.where(:method => 'online_payment', user_id: current_user.id, course_id: @course.id).update_all(status: "cancel")
      
        payment = Payment.new(
          :course_id => @course.id,
          :user_id => current_user.id,
          :method => Constants::PaymentMethod::CARD,
          :created_at => Time.now(),
          :status => Constants::PaymentStatus::SUCCESS
        )

        owned_course = current_user.courses.where(:course_id => @course.id.to_s).first
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS

        if (owned_course.save && payment.save && current_user.save)
          redirect_to root_url + "home/payment/#{payment.id.to_s}/success?p=baokim_card"
          return
        else
          render 'page_not_found', status: 404
          return
        end
      end
    end
end