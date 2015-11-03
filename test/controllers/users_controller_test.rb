require 'test_helper'

describe 'UsersController' do

  before :each do
    email = 'test9001@gmail.com'
    token = '9890fc4da44e6a569397d80738f875872adfaafc'
    @link = 'https://pedia.vn/users/reset_password?token=9890fc4da44e6a569397d80738f875872adfaafc'
    @user = User.create(
      email: 'test9001@gmail.com',
      password: '12345678',
      reset_password_token: token,
      reset_password_sent_at: Time.now
      )
  end

  after :each do
    User.delete_all
  end

  describe 'POST #forgot_password' do

    # Check
    it 'should return message when email blank' do
      post :forgot_password

      assert_response 402
      assert_equal 'Email không tồn tại, vui lòng kiểm tra lại', JSON.parse(@response.body)['message']
    end

    # Check user valid use email input
    it 'should return 200 when email valid' do
      stub_request(:post, 'http://email.pedia.vn/email_services/send_email').to_return(:status => 200, :body => '', :headers => {})

      post :forgot_password, email: @user.email, reset_password_token: @user.reset_password_token,reset_password_sent_at: @user.reset_password_sent_at

      assert_response 200
    end

  end

end