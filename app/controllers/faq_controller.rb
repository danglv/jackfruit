class FaqController < ApplicationController

  def change_time
    os = help_changing_time_link(params[:os]) || help_changing_time_link('window_78')
    @os_name = os[0]
    @video_link = os[1]
  end

  def error_report
    send_to = ['hieubt@topica.edu.vn', 'quangnk@topica.edu.vn', 'hailn@topica.edu.vn']
    subject = params[:subject]
    content = params[:content]
    if current_user
      content += '<p>Reported from:</p>'
      content += "<p>User: #{current_user.name}</p>"
      content += "<p>Email: #{current_user.email}</p>"
    end

    RestClient.post('http://email.pedia.vn/email_services/send_email',
      email: send_to,
      str_html: content,
      sender: 'Pedia<cskh@pedia.vn>',
      subj: subject
    )

    render :nothing => true
  end

  private
    def help_changing_time_link os
      {
        'window_xp' => ['Window XP' , 'https://static.pedia.vn/uploads/huong_dan/huong_dan_gioi_gio_he_thong_xp.mp4'],
        'window_78' => ['Window 7/8', 'https://static.pedia.vn/uploads/huong_dan/huong_dan_gioi_gio_he_thong_win7_8.mp4'],
        'window_10' => ['Window 10' , 'https://static.pedia.vn/uploads/huong_dan/huong_dan_gioi_gio_he_thong_win10.mp4'],
        'mac_os'    => ['Mac OS'    , 'https://static.pedia.vn/uploads/huong_dan/huong_dan_gioi_gio_he_thong_macos.mp4'],
      }[os]
    end
end