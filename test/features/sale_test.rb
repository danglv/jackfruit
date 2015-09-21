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
  end

  scenario 'User visits a course detail which is not on sale' do
    visit '/courses/test-course-2/detail'

    page.must_have_content('Test Course 2')
    page.must_have_content('199,000')
    page.wont_have_content('98,000')
    page.wont_have_content('50%')
  end

  scenario 'Athenticated user visits a course detail which is on sale and click buy' do
    u = User.where(email: 'student1@tudemy.vn').first
    page.set_rack_session(user_id: u.id)

    visit '/courses/test-course-1/detail'
    
    page.must_have_content('Test Course 1')
    page.must_have_content('98,000')
    page.wont_have_content('199,000')
    page.wont_have_content('50%')
  end
end