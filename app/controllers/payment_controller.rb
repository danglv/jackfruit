class PaymentController < ApplicationController
  before_filter :authenticate_user!
  def index
    
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