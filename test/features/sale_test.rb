require 'test_helper'

feature 'Sale' do
  scenario 'User visit a course detail' do
    visit '/courses/test-course-1/detail'

    if Capybara.current_session.driver.browser.respond_to? 'manage'
      Capybara.current_session.driver.browser.manage.window.resize_to(320, 480)
    end

    page.must_have_content('Test Course 1')
    page.must_have_content('199,000')
    page.must_have_content('98,000')
  end
end