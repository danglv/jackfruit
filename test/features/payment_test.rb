require 'test_helper'

feature 'Payment' do
  scenario '[JPA001]' do
    stub_request(:get, "http://code.pedia.vn/coupons?coupon=TEST_COUPON")
      .with(:headers => {
        'Accept'=>'*/*; q=0.5, application/xml',
        'Accept-Encoding'=>'gzip, deflate',
        'User-Agent'=>'Ruby'
        }
      )
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "it_will_be_ignored"',
                    '"created_at": "2015-09-23T10:19:22.973Z"',
                    '"expired_date": "2015-09-23T17:00:00.000Z"',
                    '"course_id": "55cb2d3044616e15ca000000"',
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"discount": 50',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )
    
    visit '/home/payment/test-course-1?coupon_code=TEST_COUPON'

    within('#login-modal') do
      fill_in('user[email]', with: 'nguyendanhtu@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('100,000')
    page.wont_have_content('199,000')
    page.wont_have_content('50%')
  end
end
