class PaymentController < ApplicationController
  include PaymentServices
  before_filter :authenticate_user!
  before_filter :validate_course

  def index
    course_alias_name = params[:alias_name]
    @course = Course.where(:alias_name => course_alias_name).first
    render 'payment'
  end

  def delivery
    if params[:is_submitted]
      name = params[:name]
      email = params[:email]
      mobile = params[:mobile]
      address = params[:address]
      city = params[:city]
      district = params[:district]

      Payment.create(
        :name => name,
        :email => email,
        :mobile => mobile,
        :address => address,
        :city => city,
        :district => district,
        :course_id => @course.id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::DELIVERY
      )
      owned_course = current_user.courses.find_or_initialize_by(
        course_id: @course.id
      )

      @course.curriculums.where(
        :type => Constants::CurriculumTypes::LECTURE
      ).map{|curriculum|
        owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
      }

      @course.set(:students => @course.students + 1)
      owned_course.type = Constants::OwnedCourseTypes::LEARNING
      owned_course.status = Constants::OwnedCourseStatus::PENDING
      current_user.save

      redirect_to root_url + "/home/payment/pending/#{@course.alias_name}"
    end
  end

  def visa
    baokim = BaoKimPayment.new
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first

    # payment = Payment.create(:course_id => course_id, :user_id => current_user.id)

    redirect_url = baokim.create_request_url({
      'order_id' =>  1,
      'business' =>  'ngoc.phungba@gmail.com',
      'total_amount' =>  @course.price,
      'shipping_fee' =>  0,
      'tax_fee' =>  0,
      'order_description' =>  'Mua ' + @course.name,
      'url_success' =>  request.protocol + request.host_with_port + '/home/payment/success?course_id=' + course_id,
      'url_cancel' =>  request.protocol + request.host_with_port + '/home/payment/cancel',
      'url_detail' =>  request.protocol + request.host_with_port + '/courses/' + @course.alias_name + '/detail'
    })

    redirect_to redirect_url
  end

  def bank

  end

  def direct

  end

  def success

  end

  def fail
    
  end

  def pending
    course_alias_name = params[:alias_name]
    @course = Course.where(:alias_name => course_alias_name).first
  end
end