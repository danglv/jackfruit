require 'test_helper'

feature 'Course' do
  before do
    stub_request(:get, /tracking.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, /email.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://flow.pedia.vn:8000/notify/message/create")
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
      .to_return(:status => 200, :body => '', :headers => {})

    @instructor = User.create(
      email: 'nguyendanhtu@pedia.vn',
      name: 'NDT',
      password: '12345678',
      password_confirmation: '12345678'
    )

    instructor_profiles = User::InstructorProfile.create([
      {
        academic_rank: 'Doctor',
        user: @instructor
      }
    ])

    @student = User.create(
      email: 'student@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )

    @courses = Course.create([
      {
        name: 'Test Course 1',
        price: 199000,
        alias_name: 'test-course-1',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      }
    ])
  end

  after do
    User.delete_all
    Course.delete_all
    Payment.delete_all
  end

  scenario 'User actives course and login' do
    invalid_activate_code = 'AN_INVALID_ACTIVATION_CODE'
    valid_activate_code = 'A_VALID_ACTIVATION_CODE'
    
    stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{invalid_activate_code}")
      .to_return(status: 422,
        body: '{"message": "Mã cod không tồn tại"}',
        headers: {}
      )

    stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{valid_activate_code}")
      .to_return(status: 200,
        body: [
          '{"_id": "A_code_id"',
          '"cod": "' + valid_activate_code + '"',
          '"created_at": ' + Time.now().to_json,
          '"expired_date": ' + (Time.now() + 2.day).to_json,
          '"course_id": "' + @courses[0].id.to_s + '"',
          '"used": 0',
          '"enabled": true',
          '"issued_by": "hainp"',
          '"price": 90000}'].join(','),
        headers: {}
      )
    
    visit '/courses/activate'

    page.must_have_content('Kích hoạt mã khóa học')

    within('.active-course-form') do
      fill_in('activation_code', with: "#{invalid_activate_code}")
      find('.btn-activate').click
    end

    page.must_have_content('Mã kích hoạt không hợp lệ, vui lòng thử lại')

    within('.active-course-form') do
      fill_in('activation_code', with: "#{valid_activate_code}")
      find('.btn-activate').click
    end   

    page.must_have_content('Mã kích hoạt hợp lệ, vui lòng')

    find('.btn-login-modal').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('BẠN ĐÃ KÍCH HOẠT KHÓA HỌC THÀNH CÔNG')
    page.must_have_content('NDT')
    page.must_have_content('Test Course 1')
    page.must_have_content('VÀO HỌC NGAY')
  end

  scenario 'User actives course and sign up' do
    valid_activate_code = 'A_VALID_ACTIVATION_CODE'
    
    stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{valid_activate_code}")
      .to_return(status: 200,
        body: [
          '{"_id": "A_code_id"',
          '"cod": "' + valid_activate_code + '"',
          '"created_at": ' + Time.now().to_json,
          '"expired_date": ' + (Time.now() + 2.day).to_json,
          '"course_id": "' + @courses[0].id.to_s + '"',
          '"used": 0',
          '"enabled": true',
          '"issued_by": "hainp"',
          '"price": 90000}'].join(','),
        headers: {}
      )
    
    visit '/courses/activate'

    page.must_have_content('Kích hoạt mã khóa học')

    within('.active-course-form') do
      fill_in('activation_code', with: "#{valid_activate_code}")
      find('.btn-activate').click
    end   

    page.must_have_content('Mã kích hoạt hợp lệ, vui lòng')

    find('.btn-register-modal').click

    within('#register-modal') do
      fill_in('user[name]', with: 'Tester')
      fill_in('user[email]', with: 'tester@gmail.com')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('BẠN ĐÃ KÍCH HOẠT KHÓA HỌC THÀNH CÔNG')
    page.must_have_content('NDT')
    page.must_have_content('Test Course 1')
    page.must_have_content('VÀO HỌC NGAY')
  end

  scenario 'User actives course by used code' do
    used_activation_code = 'USED_ACTIVATION_CODE'

    Payment.create!(cod_code: "#{used_activation_code}", course: @courses[0], user: @instructor)
    
    stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{used_activation_code}")
      .to_return(status: 200,
        body: [
          '{"_id": "A_code_id"',
          '"cod": "' + used_activation_code + '"',
          '"created_at": ' + Time.now().to_json,
          '"expired_date": ' + (Time.now() + 2.day).to_json,
          '"course_id": "' + @courses[0].id.to_s + '"',
          '"used": 0',
          '"enabled": true',
          '"issued_by": "hainp"',
          '"price": 90000}'].join(','),
        headers: {}
      )
    
    visit '/courses/activate'

    page.must_have_content('Kích hoạt mã khóa học')

    within('.active-course-form') do
      fill_in('activation_code', with: "#{used_activation_code}")
      find('.btn-activate').click
    end

    page.must_have_content('Mã kích hoạt không hợp lệ, vui lòng thử lại')
  end
end