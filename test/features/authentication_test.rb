require "test_helper"

feature "Authentication" do
  scenario "the first test" do
    visit "/users/sign_in"
    within('header') do
      find('.btn[data-target="#login-modal"]').click
    end
    fill_in('user[email]', :with => 'hainp@topica.edu.vn')
    fill_in('user[password]', :with => '12345678')
  end
end
