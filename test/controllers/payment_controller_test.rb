require 'test_helper'

class PaymentControllerTest < ActionController::TestCase
  def setup
    @user = User.create(email: "test@gmail.com", password: "123456")
    @user.save
    @course = Course.create('name' => 'A test course', 'alias_name' => 'a-test-course');
    @course.save
  end

  def teardown
    @user.destroy
    @course.destroy
  end

  test 'in payment/index page, unauthenticated user will be redirected to users/sign_in' do
    get 'index', {alias_name: 'a-test-course'}
    assert_response :redirect
    assert_match /users\/sign_in/, @response.redirect_url
  end

  test 'in payment/index page, authenticated user will get success response' do    
    sign_in :user, @user
    get 'index', {alias_name: 'a-test-course'}
    assert_response :success
  end

  test 'in payment/index page, request with invalid course alias name will get 404 response' do
    sign_in :user, @user
    get :index, {alias_name: 'an-invalid-course'}
    assert_response :missing
  end

  test "in payment/cod page, request with invalid course alias name will get 404 response" do
    sign_in :user, @user
    get :cod, {alias_name: 'an-invalid-course'}
    assert_response :missing
  end
end
