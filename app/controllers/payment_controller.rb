class PaymentController < ApplicationController
  before_filter :authenticate_user!, :list_category
  
  def index
    render 'delivery'
  end

  def delivery
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
      :district => district
    )

    redirect_to root_url + "/home/payment/success"
  end

  def visa
    
  end

  def bank
    
  end

  def direct
    
  end

  def success
    
  end
end