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
    type = 'report' if type.blank?
    content = params[:content]
    course_id = params[:course_id]
    if content.blank?
      render json:{:error => "Nội dung không được để trống"}, status: :unprocessable_entity
      return
    end

    if course_id.blank?
      render json:{:error => "Course_id không được để trống"}, status: :unprocessable_entity
      return
    end

    course = Course.where(:id => course_id).first
    if course.blank?
      render json:{:error => "Course không tồn tại"}, status: :unprocessable_entity
      return
    end

    @report = Report.new(
      :type => type,
      :content => content
    )
    @report.user = current_user
    @report.course = course

    if !@report.save
      render json:{:error => "Report thất bại"}, status: :unprocessable_entity
      return
    end
    render json:{:message => "Report thành công"}
  end

end