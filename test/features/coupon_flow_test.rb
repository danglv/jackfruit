require 'test_helper'

# Test coupon code's flow
feature 'Coupon Flow' do
  before :each do
    stub_request(:post, 'http://flow.pedia.vn:8000/notify/cod/create')
      .to_return(:status => 200, :body => '')

    stub_request(:get, /.*tracking.pedia.vn.*/)
      .to_return(:status => 200, :body => '')

    @student = User.create(
      email: 'student3@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )

    stub_coupon_request_with('test-course-2', 80)
  end

  after :each do
    @student.destroy
    Payment.destroy_all
  end

  scenario 'Keep coupon when user jumps to courses page and goes back' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_courses_page

    visit_detail_without_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')
  end

  scenario 'Saved coupon never be used for other courses' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_detail_without_coupon('test-course-1')
    must_have_contents('Test Course 1')
    # Suppose that Test course 1 and Test course 2 have the same price
    wont_have_contents('39,000', '80%', 'Mã coupon', 'không hợp lệ')
  end

  scenario 'Coupon lost when user visits other course' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_detail_without_coupon('test-course-1')
    must_have_contents('Test Course 1')
    wont_have_contents('39,000', '80%', 'Mã coupon', 'không hợp lệ')

    visit_detail_without_coupon('test-course-2')
    must_have_contents('Test Course 2')
    wont_have_contents('39,000', '80%', 'Mã coupon', 'không hợp lệ')
  end

  scenario 'Coupon should be presented in payment without coupon in url' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_payment_page('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')
  end

  scenario 'Coupon never be presented in payment of other course' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_payment_page('test-course-1')
    wont_have_contents('39,000', '80%', 'Mã coupon', 'không hợp lệ')
  end

  scenario 'Make a success payment with saved coupon' do
    visit_detail_with_coupon('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    visit_card_payment_page('test-course-2')
    must_have_contents('Test Course 2', '39,000', '80%')

    stub_card_request_with_amount(10000)
    submit_payment_by_card
    must_have_contents("Bạn đã nạp thành công 10000đ")

    stub_card_request_with_amount(29000)
    submit_payment_by_card
    must_have_contents('Test Course 2', 'thanh toán thành công', '39,000')
  end

  scenario 'User previews course and then makes a success payment' do
    stub_coupon_request_with('full-paid-course', 80)
    visit_detail_with_coupon('full-paid-course')
    must_have_contents('Full paid course', '39,000', '80%')

    find('a', :text => 'Học thử miễn phí').click
    do_login

    find('a', :text => 'MUA KHÓA HỌC').click
    must_have_contents('Full paid course', '39,000', '80%')

    find('.btn-card').click

    stub_card_request_with_amount(39000)
    submit_payment_by_card
    must_have_contents('Full paid course', 'thanh toán thành công', '39,000')

    find('.btn-to-course').click
    must_have_contents('Full paid course', 'Bài giảng')
  end

  private
    def must_have_contents(*contents)
      contents.each do |content|
        page.must_have_content(content)
      end
    end

    def wont_have_contents(*contents)
      contents.each do |content|
        page.wont_have_content(content)
      end
    end

    def stub_coupon_request_with(course_alias, discount)
      course = Course.where(alias_name: course_alias).first

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
                      '"discount": ' + discount.to_s,
                      '"return_value": "50"',
                      '"issued_by": "hailn"}'].join(','),
                    :headers => {}
                  )
    end

    def visit_detail_with_coupon(course_alias)
      visit "/courses/#{course_alias}/detail?coupon_code=A_VALID_COUPON"
    end

    def visit_detail_without_coupon(course_alias)
      visit "/courses/#{course_alias}/detail"
    end

    def visit_courses_page
      visit '/courses'
    end

    def visit_payment_page(course_alias)
      visit "/home/payment/#{course_alias}"
      within('#login-modal') do
        fill_in('user[email]', with: @student.email)
        fill_in('user[password]', with: '12345678')
        find('.btn-login-submit').click
      end
    end

    def stub_card_request_with_amount(amount)
      stub_request(:post, "https://www.baokim.vn/the-cao/restFul/send")
        .to_return(:status => 200, :body => "{\"amount\": #{amount}}", :headers => {})
    end

    def visit_card_payment_page(course_alias)
      visit "/home/payment/card/#{course_alias}?p=baokim_card"
      do_login
    end

    def do_login
      within('#login-modal') do
        fill_in('user[email]', with: @student.email)
        fill_in('user[password]', with: '12345678')
        find('.btn-login-submit').click
      end
    end

    def submit_payment_by_card
      within('.form-card') do
        fill_in('pin_field', with: 34903384924074)
        fill_in('seri_field', with: 36108200046632)
        find('.purchase-button').click
      end
    end
end