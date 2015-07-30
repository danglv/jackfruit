require 'test_helper'

class PaymentControllerTest < ActionController::TestCase
  def setup
    @user = User.create(email: "test@gmail.com", password: "123456")
    @user.save
  end

  def teardown
    @user.delete
  end

  test "delivery" do
  	sign_in :user, @user
    post :delivery
    assert_redirected_to controller: "courses", action: "index"
  end
end
