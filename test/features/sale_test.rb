require 'test_helper'

feature 'Sale' do
  scenario 'User visits a course detail which is on sale' do
    visit '/courses/test-course-1/detail'

    # if Capybara.current_session.driver.browser.respond_to? 'manage'
    #   Capybara.current_session.driver.browser.manage.window.resize_to(320, 480)
    # end

    page.must_have_content('Test Course 1')
    page.must_have_content('199,000')
    page.must_have_content('98,000')
    page.must_have_content('50%')
    page.must_have_content('8 cơ hội')
    page.wont_have_content('NaN')
  end

  scenario 'User visits a course detail which is not on sale' do
    visit '/courses/test-course-2/detail'

    page.must_have_content('Test Course 2')
    page.must_have_content('199,000')
    page.wont_have_content('98,000')
    page.wont_have_content('50%')
  end

  scenario 'User visits a course with a coupon' do
    course = Course.where(alias_name: 'test-course-2').first

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
                    '"course_id": "' + course.id + '"',
                    '"max_used": 1',
                    '"discount": 80',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    visit '/courses/test-course-2/detail?coupon_code=A_VALID_COUPON'

    page.must_have_content('Test Course 2')
    page.must_have_content('39,000')
    page.must_have_content('80%')
  end
end