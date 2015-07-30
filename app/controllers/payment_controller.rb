class PaymentController < ApplicationController
  before_filter :authenticate_user!
  before_filter :validate_course

  def index
    render 'delivery'
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
        :course_id => course_id,
        :user_id => current_user.id,
        :method => Constants::PaymentMethod::DELIVERY
      )
      owned_course = current_user.courses.find_or_initialize_by(
        course_id: course_id
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

      redirect_to root_url + "/home/payment/success?course_id="+course_id
    end
  end

  def visa

  end

  def bank

  end

  def direct

  end

  def success

  end

  def pending
    
  end
end