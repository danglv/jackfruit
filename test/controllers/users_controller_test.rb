require 'test_helper'

describe 'UsersController' do

  before :each do
    @user = User.create(
      email: 'test9001@gmail.com',
      password: '12345678',
      )
  end

  after :each do
    User.delete_all
  end

  describe 'POST #forgot_password' do

    # Check email input
    it 'should return message when email blank' do
      post :forgot_password

      assert_response 402
      assert_equal 'Email không tồn tại, vui lòng kiểm tra lại', JSON.parse(@response.body)['message']
    end

    # Check user valid use email input
    it 'should return 200 when email valid' do
      stub_request(:post, 'http://email.pedia.vn/email_services/send_email').to_return(:status => 200, :body => '', :headers => {})

      assert_response 200
    end

  end

end