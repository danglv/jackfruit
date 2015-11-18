module ErrorReportHelper

  def self.send_on_cod_activating_failed message, params = {}
    send_to = ['hieubt@topica.edu.vn', 'quangnk@topica.edu.vn', 'phuongvtm2@topica.edu.vn', 'hoptq@topica.edu.vn']
    
    content = "<p>Message: #{message}</p>"

    params.each do |key, value|
      content += "<p>#{key}: #{value}</p>"
    end

    report_by_email send_to, content, 'COD Activating Error'
  end

  def self.report_by_email to, content, subject
    RestClient.post('http://email.pedia.vn/email_services/send_email',
      email: to,
      str_html: content,
      sender: 'Pedia<cskh@pedia.vn>',
      subj: subject
    )
  end
end