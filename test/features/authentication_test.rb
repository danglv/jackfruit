require "test_helper"

feature "Authentication" do
  before do
    # NOTE: better move to seed.rb
    User.create([{email: 'nguyendanhtu@tudemy.vn', password: '12345678', password_confirmation: '12345678'}])
    Category.create([{name: 'Test Category 1'}])
  end

  after do
    Capybara.reset_sessions!
    User.destroy_all
    Category.destroy_all
  end
  
  scenario "the first test" do
    visit "/"

    within('header') do
      find('.btn[data-target="#login-modal"]').click
    end

    within('#login-modal.modal.fade') do
      fill_in('user[email]', :with => 'nguyendanhtu@tudemy.vn')
      fill_in('user[password]', :with => '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Category 1');
  end
end
