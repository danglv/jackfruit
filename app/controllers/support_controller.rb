class SupportController < ApplicationController
  before_filter :authenticate_user!, only: [:send_report]
  def index
    name = params[:name]
    email = params[:email]
    content = params[:content]
    feedback = Feedback.create(
      :name => name,
      :email => email,
      :content => content
    )
    redirect_to session[:previous_url] || root_url
  end

  def send_report
    type = params[:type]
    content = params[:content]
    course_id = params[:course_id]
    course = Course.where(:id => course_id).first
    report = Report.new(
      :type => type,
      :content => content
    )
    report.user = current_user
    report.course = course
    binding.pry
    if report.save
      render json:{:messge => "Report thành công"}
      return
    end
    render json:{messge => "Report thất bại"}, status: :unprocessable_entity
  end

end