require 'test_helper'

feature 'Authentication' do
  before do
    User.create([
      {
        email: 'nguyendanhtu@tudemy.vn',
        password: '12345678',
        password_confirmation: '12345678'
      }
    ])

    Category.create([{ name: 'Test Category 1' }])
  end

  after do
    User.destroy_all
    Category.destroy_all
  end

  scenario 'home page test' do
    visit '/'

    page.must_have_content('Facebook')
  end

  scenario 'the first test' do
    visit '/'

    find('.link-exist-account').click

    within('.form-login') do
      fill_in('user[email]', with: 'nguyendanhtu@tudemy.vn')
      fill_in('user[password]', with: '12345678')
      find('.btn-login').click
    end

    page.must_have_content('Test Category 1')
  end
end
