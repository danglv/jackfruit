require 'test_helper'

feature 'Payment' do
  before do
    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_VALID_COUPON")
      .with(:headers => {
        'Accept'=>'*/*; q=0.5, application/xml',
        'Accept-Encoding'=>'gzip, deflate',
        'User-Agent'=>'Ruby'
        }
      )
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_VALID_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"discount": 50',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )
  end

  after do
    User.where(email: 'student1@tudemy.vn').first.courses.destroy_all
  end

  scenario '[JPA001]' do
    if Capybara.current_session.driver.browser.respond_to? 'manage'
      Capybara.current_session.driver.browser.manage.window.resize_to(1280, 800)
    end

    visit '/courses/test-course-1/detail?coupon_code=A_VALID_COUPON'

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: 'student1@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('99,500')
    page.must_have_content('199,000')
    page.must_have_content('50%')
  end

  scenario '[JPA002]' do
    # if Capybara.current_session.driver.browser.respond_to? 'manage'
    #   Capybara.current_session.driver.browser.manage.window.resize_to(1280, 800)
    # end

    visit '/courses/test-course-1/detail'

    find('#coupon-dropdown-button').click

    within('#coupon-dropdown') do
      fill_in('coupon_code', :with => 'A_VALID_COUPON')
      find('.coupon-submit').click
    end

    find('.buy-button').click

    within('#login-modal') do
      fill_in('user[email]', with: 'student1@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('99,500')
    page.must_have_content('199,000')
    page.must_have_content('50%')
  end

  scenario '[JPA003] phone card payment success' do
    stub_request(:post, "https://www.baokim.vn/the-cao/restFul/send")
      .to_return(:status => 200, :body => '{"amount": 199000}', :headers => {})

    visit '/home/payment/card/test-course-1?p=baokim_card'

    within('#login-modal') do
      fill_in('user[email]', with: 'nguyendanhtu@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    within('.form-card') do
      fill_in('pin_field', with: 34903384924074)
      fill_in('seri_field', with: 36108200046632)
      find('.purchase-button').click
    end

    page.must_have_content('Thành công')
  end

  scenario '[JPA004] phone card payment fail' do
    stub_request(:post, "https://www.baokim.vn/the-cao/restFul/send")
      .to_return(:status => 406,
                 :body => '{"errorMessage": "Error", "transaction_id": 1}',
                 :headers => {})

    visit '/home/payment/card/test-course-1?p=baokim_card'

    within('#login-modal') do
      fill_in('user[email]', with: 'nguyendanhtu@tudemy.vn')
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
end
