require 'test_helper'

feature 'Payment' do
  before :each do
    stub_request(:post, 'http://flow.pedia.vn:8000/notify/cod/create')
      .to_return(:status => 200, :body => '')

    stub_request(:get, /.*tracking.pedia.vn.*/)
      .to_return(:status => 200, :body => '')

    @instructor = User.create(
      email: 'nguyendanhtu@pedia.vn',
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
      email: 'student3@pedia.vn',
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
      },
      {
        name: 'Test Course 2',
        price: 199000,
        alias_name: 'test-course-2',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      },
      {
        name: 'Test Course 3',
        price: 199000,
        alias_name: 'test-course-3',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      }
    ])

    @campaign = Sale::Campaign.create(
      title: 'Test Sale Campaign 1',
      start_date: Time.now,
      end_date: Time.now + 2.days
    )

    @sale_packages = Sale::Package.create([
      {
        title: 'Test Sale Package 1',
        price: 98000,
        campaign: @campaign,
        courses: [@courses[0]],
        participant_count: 2,
        max_participant_count: 10,
        start_date: Time.now,
        end_date: Time.now + 2.days
      },
      {
        title: 'Test Sale Package 2',
        price: 98000,
        campaign: @campaign,
        courses: [@courses[2]],
        participant_count: 2,
        max_participant_count: 10,
        start_date: Time.now,
        end_date: Time.now + 2.days
      }
    ])
  end

  after :each do
    Sale::Campaign.delete_all
    User.delete_all
    Course.delete_all
    Payment.destroy_all
  end

  scenario '[JPA001]' do
    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_VALID_COUPON")
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_VALID_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + @courses[0].id.to_s + '"',
                    '"discount": 50',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )
    # if Capybara.current_session.driver.browser.respond_to? 'manage'
    #   Capybara.current_session.driver.browser.manage.window.resize_to(1280, 800)
    # end

    visit '/courses/test-course-1/detail?coupon_code=A_VALID_COUPON'

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('99,000')
    page.must_have_content('199,000')
    page.must_have_content('50%')
  end

  scenario '[JPA002]' do
    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_VALID_COUPON")
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_VALID_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + @courses[0].id.to_s + '"',
                    '"discount": 50',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    visit '/courses/test-course-1/detail'

    find('#coupon-dropdown-button').click

    within('#coupon-dropdown') do
      fill_in('coupon_code', :with => 'A_VALID_COUPON')
      find('.coupon-submit').click
    end

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('99,000')
    page.must_have_content('199,000')
    page.must_have_content('50%')
  end

  scenario '[JPA003] phone card payment success' do
    stub_request(:post, "https://www.baokim.vn/the-cao/restFul/send")
      .to_return(:status => 200, :body => '{"amount": 199000}', :headers => {})
      
    stub_request(:post, 'http://flow.pedia.vn:8000/notify/message/create')
      .to_return(:status => 200, body: '', headers: {})  

    stub_request(:post, 'http://mercury.pedia.vn/api/issue/close')
      .to_return(:status => 200, body: '', headers: {})

    visit '/home/payment/card/test-course-1?p=baokim_card'

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    within('.form-card') do
      fill_in('pin_field', with: 34903384924074)
      fill_in('seri_field', with: 36108200046632)
      find('.purchase-button').click
    end

    page.must_have_content('Thành công')
    @student.courses.destroy_all
  end

  scenario '[JPA004] phone card payment fail' do
    stub_request(:post, "https://www.baokim.vn/the-cao/restFul/send")
      .to_return(:status => 406,
                 :body => '{"errorMessage": "Error", "transaction_id": 1}',
                 :headers => {})

    visit '/home/payment/card/test-course-1?p=baokim_card'

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    within('.form-card') do
      fill_in('pin_field', with: 34903384924074)
      fill_in('seri_field', with: 36108200046632)
      find('.purchase-button').click
    end

    page.must_have_content('Error')
  end

  scenario '[JPA005] zero amount payment' do
    course = @courses[2]
    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_ZERO_AMOUNT_COUPON")
      .with(:headers => {
        'Accept'=>'*/*; q=0.5, application/xml',
        'Accept-Encoding'=>'gzip, deflate',
        'User-Agent'=>'Ruby'
        }
      )
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_ZERO_AMOUNT_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + course.id + '"', 
                    '"discount": 100',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    stub_request(:post, 'http://flow.pedia.vn:8000/notify/message/create')
      .to_return(:status => 200, body: '', headers: {})

    stub_request(:post, 'http://mercury.pedia.vn/api/issue/close')
      .to_return(:status => 200, body: '', headers: {})

    visit '/courses/test-course-3/detail?coupon_code=A_ZERO_AMOUNT_COUPON'      

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Chúc mừng, bạn đã tham gia vào khóa học')
    page.must_have_content('Test Course 3')
    page.wont_have_content('199,000')
    page.wont_have_content('Chi phí')
    page.wont_have_content('Trạng thái')
  end

  scenario '[JPA006] cod payment' do
    stub_request(:post, 'http://code.pedia.vn/cod/create_cod')
      .to_return(
        status: 200,
        body: [
          '{"cod_codes": "[abcdef]"}'
        ].join,
        headers: {}
      )

    visit '/courses/test-course-1/detail'

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    find('.fa-shopping-cart').click

    within('.cod-form') do
      fill_in('mobile', with: '123456')
      fill_in('address', with: 'Sahara')
      select('Hà Nội', from: 'city')
      fill_in('district', with: 'HK')
      find('.purchase-button').click
    end

    page.must_have_content('Đang xử lý')
    page.must_have_content('98,000')
  end

  # scenario '[JPA007] User can cancel a COD payment' do
  #   stub_request(:post, 'http://mercury.pedia.vn/api/issue/close')
  #     .to_return(:status => 200, body: '', headers: {})

  #   visit '/courses/test-course-1/detail'

  #   find('.buy-button').click

  #   within('#login-modal') do
  #     fill_in('user[email]', with: @student.email)
  #     fill_in('user[password]', with: '12345678')
  #     find('.btn-login-submit').click
  #   end

  #   find('.fa-shopping-cart').click

  #   within('.cod-form') do
  #     fill_in('mobile', with: '123456')
  #     fill_in('address', with: 'Sahara')
  #     select('Hà Nội', from: 'city')
  #     fill_in('district', with: 'HK')
  #     find('.purchase-button').click
  #   end

  #   visit '/courses/test-course-1/detail'

  #   within('.cancel-text') do
  #     find('a').click
  #   end

  #   page.must_have_content('Mua khóa học')
  #   page.wont_have_content('Kích hoạt mã COD')

  #   find('.buy-button').click

  #   find('.fa-shopping-cart').click

  #   within('.cod-form') do
  #     fill_in('mobile', with: '123456')
  #     fill_in('address', with: 'Sahara')
  #     select('Hà Nội', from: 'city')
  #     fill_in('district', with: 'HK')
  #     find('.purchase-button').click
  #   end

  #   visit '/courses/test-course-1/detail'

  #   within('.cancel-text') do
  #     find('a').click
  #   end

  #   page.must_have_content('Mua khóa học')
  #   page.wont_have_content('Kích hoạt mã COD')
  # end

  scenario '[JPA008] User input expired coupon' do
    course = @courses[0]

    stub_request(:get, "http://code.pedia.vn/coupon?coupon=AN_EXPIRED_COUPON")
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "AN_EXPIRED_COUPON"',
                    '"created_at": ' + (Time.now() - 2.days).to_json,
                    '"expired_date": ' + (Time.now() - 1.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + course.id + '"', 
                    '"discount": 100',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    visit '/courses/test-course-1/detail?coupon_code=AN_EXPIRED_COUPON'

    page.must_have_content("Mã coupon AN_EXPIRED_COUPON không hợp lệ")
  end

  scenario '[JPA009] cod payment success' do
    course = @courses[1]

    stub_request(:post, 'http://code.pedia.vn/cod/create_cod')
      .to_return(
        status: 200,
        body: [
          '{"cod_codes": "[abcdef]"}'
        ].join,
        headers: {}
      )

    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_VALID_COUPON_1")
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_VALID_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + course.id + '"',
                    '"discount": 60',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    visit '/courses/test-course-2/detail?coupon_code=A_VALID_COUPON_1'

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: @student.email)
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    find('.fa-shopping-cart').click

    within('.cod-form') do
      fill_in('mobile', with: '123456')
      fill_in('address', with: 'Sahara')
      select('Hà Nội', from: 'city')
      fill_in('district', with: 'HK')
      find('.purchase-button').click
    end

    page.must_have_content('Đang xử lý')
    page.must_have_content('79,000')
  end
end
