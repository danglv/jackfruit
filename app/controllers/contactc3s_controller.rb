class Contactc3sController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def insert

    exitst_contact = Contactc3.where(:mobile => params[:mobile], :course_id => params[:course_id]).first

    if exitst_contact
      render json: {:message => "Contact này đã có trong hệ thống."}, status: :unprocessable_entity
      return
    end

    Contactc3.insert_contactc3(
      :name => params[:name],
      :mobile => params[:mobile],
      :email => params[:email],
      :course_id => params[:course_id],
      :course_name => params[:course_name],
      :msg => params[:msg],
      :type => params[:type]
    )

    head :ok
  end
end
