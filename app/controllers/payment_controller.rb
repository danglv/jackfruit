class PaymentController < ApplicationController
  include PaymentServices
  before_filter :authenticate_user!
  before_action :validate_course, :except => [:status, :success, :cancel, :pending]
  before_action :validate_payment, :only => [:status, :success, :cancel, :pending]

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

      create_course_for_user()

      redirect_to root_url + "/home/payment/#{payment.id.to_s}/pending"
    end
  end

  def online_payment
    payment_service_provider = params[:p]
    alias_name = params[:alias_name]
    @course = Course.where(:alias_name => alias_name).first

    payment = Payment.create(
      :course_id => @course.id,
      :user_id => current_user.id,
      :method => Constants::PaymentMethod::ONLINE_PAYMENT
    )

    create_course_for_user()

    if payment_service_provider == 'baokim'
      baokim = BaoKimPayment.new

      redirect_url = baokim.create_request_url({
        'order_id' =>  payment.id,
        'business' =>  'ngoc.phungba@gmail.com',
        'total_amount' =>  @course.price,
        'shipping_fee' =>  0,
        'tax_fee' =>  0,
        'order_description' =>  @course.name,
        'url_success' =>  request.protocol + request.host_with_port + '/home/payment/' + payment.id + '/success?p=baokim',
        'url_cancel' =>  request.protocol + request.host_with_port + '/home/payment/' + payment.id + '/cancel?p=baokim',
        'url_detail' =>  request.protocol + request.host_with_port + '/courses/' + @course.alias_name + '/detail'
      })

      redirect_to redirect_url
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
      params.delete('p')
      params.delete('action')
      params.delete('id')
      params.delete('controller')
      
      baokim = BaoKimPayment.new
      @course = Course.where(id: @payment.course_id).first
      
      if baokim.verify_response_url(params)
        owned_course = current_user.courses.where(course_id: @course.id).first
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS
        owned_course.save
      else
        render 'page_not_found', status: 404
      end
    end
  end

  # GET
  def cancel
    payment_service_provider = params[:p]
    if payment_service_provider == 'baokim'
      params.delete('p')
      params.delete('action')
      params.delete('id')
      params.delete('controller')
      
      baokim = BaoKimPayment.new
      @course = Course.where(id: @payment.course_id).first
      
      if baokim.verify_response_url(params)
        owned_course = current_user.courses.where(course_id: @course.id).first
        owned_course.payment_status = Constants::PaymentStatus::CANCEL
        owned_course.save
      else
        render 'page_not_found', status: 404
      end
    end
  end

  # GET
  def pending
  end

  private
    def validate_payment
      payment_id = params[:id]
      @payment = Payment.where(:id => payment_id).first

      if @payment.blank?
        render 'page_not_found'
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
end