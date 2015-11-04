require 'test_helper'

describe 'UsersController' do

  before :each do
    email = 'test9001@gmail.com'
    token = '9890fc4da44e6a569397d80738f875872adfaafc'
    @link = 'https://pedia.vn/users/reset_password?token=9890fc4da44e6a569397d80738f875872adfaafc'
    @user = User.create!(
      email: 'test9001@gmail.com',
      password: '12345678',
      reset_password_token: token,
      reset_password_sent_at: Time.now,
    )

    @course = Course.create(
      name: 'Course 1',
      price: 190000,
      alias_name: 'course_1',
      enabled: true,
      user: @user,
    )

    instructor_profile = User::InstructorProfile.create(
      user: @user
    )
  end

  after :each do
    User.delete_all
  end

  describe 'GET #index' do
  end

  describe 'POST #create' do

    it 'should return message when not have user' do

      post :create

      assert_response :unprocessable_entity
      assert_equal 'Thiếu param user', JSON.parse(@response.body)['error']
    end

    it 'should return message when user not save' do
      post :create, user: @user.as_json

      assert_response 200
      assert_match 'error', response.body
      assert_match 'email', response.body
    end

    it 'should return message when have' do
      post :create, user: 'abcxyz'

      assert_match 'error', response.body
    end

    it 'should return error when user is not a hash' do
      user_data = "An invalid hash object"
      post :create, user: user_data

      assert_response 200
      assert_match 'error', response.body
    end

    it 'should save valid instructor profile' do
      user_data = {
        email: 'test03@gmail.com',
        instructor_profile: {
          function: 'This is a function'
        }
      }

      post :create, user: user_data

      assert_response 200
      assert_match 'test03@gmail.com', response.body
      assert_match 'This is a function', response.body
    end

    it 'should ignore invalid instructor profile' do
      user_data = {
        email: 'test03@gmail.com',
        instructor_profile: "Not a valid hash"
      }

      post :create, user: user_data

      assert_response 200
      assert_match 'test03@gmail.com', response.body
      assert_match '"function":""', response.body
    end

    it 'should return message when user can save' do
      user_new = User.new(
        email: 'test02@gmail.com'
      )
      instructor_profile_new = User::InstructorProfile.new(
        user: user_new
      )

      post :create, user: user_new.as_json

      assert_response 200
      assert_match 'test02@gmail.com', response.body
      assert_equal 0, JSON.parse(response.body)['money']
    end
  end

  describe 'POST #create_user_for_mercury' do
    it 'should return message when email blank' do
      post :create_user_for_mercury

      assert_response :unprocessable_entity
      assert_equal 'Email is empty', JSON.parse(@response.body)['message']
    end

    it 'should return message when email exist' do
      post :create_user_for_mercury, email: @user.email

      assert_equal 'Exist email', JSON.parse(@response.body)['status']
    end

    it 'should return status create user when user saved' do
      stub_request(:get, /tracking.pedia.vn/).to_return(:status => 'Create user', :body => '', :headers => {})

      post :create_user_for_mercury, email: 'test9002@gmail', name: 'mercury_user', phone: '0918261892', password: '135792468'

      assert_equal 'Create user', JSON.parse(@response.body)['status']
    end
  end

  describe 'GET #hocthu' do
    it 'when user do not sign in' do
      get :hoc_thu

      assert_response :success
    end

    it 'should redirect to landingpage if user sign in success' do
      @current_user = @user
      sign_in @current_user

      get :hoc_thu

      assert_response :redirect
      assert_redirected_to "http://tuduylamchu.pedia.vn/hocthu.html"
    end
  end

  describe 'POST #sign_up_with_email' do

  end

  describe 'GET #update_wishlist' do
    it 'should return message when course_id blank' do
      sign_in @user

      get :update_wishlist

      assert_response :unprocessable_entity
      assert_equal 'Course_id không có', JSON.parse(@response.body)['message']
    end

    it 'should return ok when course_id valid' do
      sign_in @user

      get :update_wishlist, course_id: '1234abc5678'

      assert_response :success
      assert_equal 'ok', JSON.parse(@response.body)['message']
    end
  end

  describe 'GET #select_course' do

  end

  describe 'POST #active_course' do
    it 'should return message ok when have course_id' do
      @user.courses.create({
        course_id: @course.id,
        payment_status: 'success',
        type: 'learning'
      })
      post :active_course, course_id: @course.id, user_id: @user.id

      assert_response 200
      assert_equal 'Thành công!', JSON.parse(@response.body)['message']
    end

    # it 'should return message fail when not save user' do

    # end
  end

  describe 'POST create_instructor' do
    it 'should return message when params blank' do
      post :create_instructor

      assert_response :unprocessable_entity
      assert_equal 'Chưa truyền dữ liệu!', JSON.parse(@response.body)['message']
    end
  end

  describe 'GET #edit_profile' do
    it '' do
    end
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
      stub_request(:post, /email.pedia.vn/).to_return(:status => 200, :body => '', :headers => {})

      post :forgot_password, email: @user.email, reset_password_token: @user.reset_password_token,reset_password_sent_at: @user.reset_password_sent_at

      assert_response 200
    end
  end
end