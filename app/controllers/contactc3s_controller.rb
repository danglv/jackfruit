class Contactc3sController < ApplicationController

  def insert
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
