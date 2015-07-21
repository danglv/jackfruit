class PaymentController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
    render 'delivery'
  end

  def delivery
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
    if params[:is_submitted]
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
        :course_id => course_id,
        :user_id => current_user.id
      )

      redirect_to root_url + "/home/payment/success?course_id="+course_id
    end
  end

  def visa
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
  end

  def bank
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
  end

  def direct
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
  end

  def success
    course_id = params[:course_id]
    @course = Course.where(:id => course_id).first
  end
end