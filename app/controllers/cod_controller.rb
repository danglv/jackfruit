class CodController < ApplicationController

  def activate
    if request.patch?
      @cod_code = params[:cod_code]
      if @cod_code.blank?
        flash.now[:error] = "Hãy nhập mã COD để kích hoạt khóa học"
        return
      end
      payment = Payment.where(:cod_code => @cod_code).first
      if payment.blank?
        flash.now[:error] = "Mã COD không hợp lệ"
        return
      end
      if payment.status == Constants::PaymentStatus::SUCCESS
        flash.now[:error] = "Mã COD đã được kích hoạt"
        return
      end

      @user = payment.user
      @course = payment.course
      owned_course = @user.courses.where(course_id: payment.course_id.to_s).last
      owned_course.payment_status = Constants::PaymentStatus::SUCCESS
      payment.status = Constants::PaymentStatus::SUCCESS
      payment.save
      owned_course.save

      sign_in :user, @user

      @should_show_info = @user.valid_password?('12345678')
      @should_show_info &= @user.courses.count == 1

      if @should_show_info
        content = email_template({
          title: 'Chào mừng bạn đến với Pedia',
          course_name: @course.name,
          course_alias: @course.alias_name,
          email: @user.email,
          password: '12345678'
        })
        RestClient.post('http://email.pedia.vn/email_services/send_email',
          email: @user.email,
          str_html: content,
          sender: 'Pedia<cskh@pedia.vn>',
          subj: 'Chào mừng đến với Pedia'
        )
      end

      render 'success'
    end
  end

  private
    def email_template params = {}
      file_path = Rails.root.join('app/views/cod/_email_template.html.erb')
      template = File.new(file_path).read
      result = ERB.new(template).result(OpenStruct.new(params).instance_eval { binding })
      return result
    end
end