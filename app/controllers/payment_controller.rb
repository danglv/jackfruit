class PaymentController < ApplicationController
  include PaymentServices

  before_filter :authenticate_user!, :except => [:error]
  before_action :validate_course, :except => [:status, :success, :cancel, :error]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending, :import_code]

  # GET
  def index
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

      payment = Payment.create(
        :name => name,
        :email => email,
        :mobile => mobile,
        :address => address,
        :city => city,
        :district => district,
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::COD
      )

      #generated cod code for user
      payment.generate_cod_code

      create_course_for_user()

      redirect_to root_url + "/home/payment/#{payment.id.to_s}/pending?alias_name=#{@course.alias_name}"
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
      payment = Payment.create(
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::ONLINE_PAYMENT
      )

      create_course_for_user()

      if payment_service_provider == 'baokim'
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
 
      if revice_data.code.to_i == 200
        current_user.money += data['amount'].to_i

        if current_user.save
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
      owned_course = current_user.courses.where(course_id: @payment.course_id.to_s).first
      owned_course.payment_status = Constants::PaymentStatus::SUCCESS

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