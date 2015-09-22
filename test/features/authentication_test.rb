require 'test_helper'

feature 'Authentication' do
  scenario 'the first test' do
    visit '/'

    within('header') do
      find('.btn[data-target="#login-modal"]').click
    end

    within('#login-modal.modal.fade') do
      fill_in('user[email]', with: 'nguyendanhtu@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login-submit').click
    end

    page.must_have_content('Test Category 1')
  end
end
