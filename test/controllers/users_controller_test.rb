require 'test_helper'

describe 'UsersController' do

  before :each do
    stub_request(:get, /tracking.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://flow.pedia.vn:8000/notify/message/create")
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
      .to_return(:status => 200, :body => '', :headers => {})

    email = 'test9001@gmail.com'
    token = '9890fc4da44e6a569397d80738f875872adfaafc'
    @link = 'https://pedia.vn/users/reset_password?token=9890fc4da44e6a569397d80738f875872adfaafc'
    @user = User.create!(
      email: 'test9001@gmail.com',
      password: '12345678',
      reset_password_token: token,
      reset_password_sent_at: Time.now,
    )

    @student_user = User.create!(
      email: 'student@gmail.com',
      password: '12345678'
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
    Course.delete_all
    Payment.delete_all
  end

  describe 'GET #index' do
  end

  describe 'POST #create' do

    it '[JU201] should return message when not have user' do

      post :create

      assert_response :unprocessable_entity
      assert_equal 'Thiếu param user', JSON.parse(@response.body)['error']
    end

    it '[JU202] should return message when user not save' do
      post :create, user: @user.as_json

      assert_response 200
      assert_match 'error', response.body
      assert_match 'email', response.body
    end

    it '[JU203] should return message when have' do
      post :create, user: 'abcxyz'

      assert_match 'error', response.body
    end

    # it '[JU204] should return error when user is not a hash' do
    #   user_data = "An invalid hash object"
    #   post :create, user: user_data

    #   assert_response :unprocessable_entity
    #   assert_match 'error', response.body
    # end

    it '[JU205] should save valid instructor profile' do
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

    # it '[JU206] should ignore invalid instructor profile' do
    #   user_data = {
    #     email: 'test03@gmail.com',
    #     instructor_profile: "Not a valid hash"
    #   }

    #   post :create, user: user_data

    #   assert_response 200
    #   assert_match 'test03@gmail.com', response.body
    #   assert_match '"function":""', response.body
    # end

    it '[JU207] should return message when user can save' do
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
    it '[JU301] Should return message when email blank' do
      post :create_user_for_mercury

      assert_response :unprocessable_entity
      assert_equal 'Email is empty', JSON.parse(@response.body)['message']
    end

    it '[JU302] Should return message when email exist' do
      post :create_user_for_mercury, email: @user.email

      assert_equal 'Exist email', JSON.parse(@response.body)['status']
    end

    it '[JU303] Should return message when user can not save' do
      post :create_user_for_mercury, email: 123

      assert_response :unprocessable_entity
      assert_equal 'Can not save', JSON.parse(@response.body)['message']
    end

    it '[JU304] Should tracking when user can save' do
      stub_request(:get, /tracking.pedia.vn/).to_return(:status => 'Create user', :body => '', :headers => {})

      post :create_user_for_mercury, email: 'test04@gmail.com', name: 'test04', phone: '0986103650'

      assert_response 200
      assert_equal 'Create user', JSON.parse(@response.body)['status']
      assert_match 'user_id', response.body

    end
  end

  describe 'GET #hocthu' do
    it '[JU401] When user do not sign in' do
      get :hoc_thu

      assert_response :success
    end

    it '[JU402] Should redirect to landingpage if user sign in success' do
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
    it '[JU601] should return message when course_id blank' do
      sign_in @user

      get :update_wishlist

      assert_response :unprocessable_entity
      assert_equal 'Course_id không có', JSON.parse(@response.body)['message']
    end

    it '[JU601] should return ok when course_id valid' do
      sign_in @user

      get :update_wishlist, course_id: '1234abc5678'

      assert_response :success
      assert_equal 'ok', JSON.parse(@response.body)['message']
    end
  end

  describe 'GET #select_course' do

  end

  describe 'POST #active_course' do
    it '[JU701] should return message ok when have course_id' do
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
    it '[JU701] should return message when params blank' do
      post :create_instructor

      assert_response :unprocessable_entity
      assert_equal 'Chưa truyền dữ liệu!', JSON.parse(@response.body)['message']
    end
  end

  describe 'GET #edit_profile' do
    it '[JU801] ' do
    end
  end

  describe 'POST #forgot_password' do

    # Check email input
    it '[JU901] should return message when email blank' do
      post :forgot_password

      assert_response 402
      assert_equal 'Email không tồn tại, vui lòng kiểm tra lại', JSON.parse(@response.body)['message']
    end

    # Check user valid use email input
    it '[JU901] should return 200 when email valid' do
      stub_request(:post, /email.pedia.vn/).to_return(:status => 200, :body => '', :headers => {})

      post :forgot_password, email: @user.email, reset_password_token: @user.reset_password_token,reset_password_sent_at: @user.reset_password_sent_at

      assert_response 200
    end
  end

  describe 'POST #create_cod_user' do
    it '[JU1001] Should return 422 if email blank' do
      post :create_cod_user, {
        :course_id => 'INVALID_ID',
        :new_price => '99,000'
      }

      assert_response :unprocessable_entity
      assert_equal 'email không được bỏ trống', JSON.parse(response.body)['message']
    end

    it '[JU1002] Should return 422 if course_id blank' do
      post :create_cod_user, {
        :email => 'TEST_EMAIL',
        :new_price => '99,000a'
      }

      assert_response :unprocessable_entity
      assert_equal 'course_id không được bỏ trống', JSON.parse(response.body)['message']
    end

    it '[JU1003] Should return 422 if new_price blank' do
      post :create_cod_user, {
        :email => 'TEST_EMAIL',
        :course_id => 'INVALID_ID'
      }

      assert_response :unprocessable_entity
      assert_equal 'new_price không được bỏ trống', JSON.parse(response.body)['message']
    end

    # ==

    it '[JU1004] Should return 422 if course is not exist' do
      post :create_cod_user, {
        :email => 'TEST_EMAIL',
        :course_id => 'INVALID_ID',
        :new_price => '99,000'
      }

      assert_response :unprocessable_entity
      assert_equal 'Không tìm thấy khoá học.', JSON.parse(response.body)['message']
    end

    it '[JU1005] Should return 422 if user bought this course' do
      payment = Payment.create(
        :user_id => @student_user.id,
        :course_id => @course.id,
        :method => 'cod',
        :status => 'success'
      )

      post :create_cod_user, {
        :email => @student_user.email,
        :course_id => @course.id,
        :new_price => '99,000'
      }

      assert_response :unprocessable_entity
      assert_equal 'User đã mua khoá học này.', JSON.parse(@response.body)['message']
    end

    it '[JU1006] Should return 200 if user not exist' do
      stub_request(:post, /code.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})

      post :create_cod_user, {
        email: 'nguyenduyvu21.02.1995@gmail.com',
        name: 'Nguyễn Duy Vũ',
        mobile: '0967648624',
        address: 'Thành phố Hồ Chí Minh',
        course_id: @course.id,
        new_price: '90,000',
        coupon: 'test'
      }

      new_payment = @assigns['payment']

      assert_response :success
      assert_not_nil JSON.parse(@response.body)['user_id']
      assert_equal "", JSON.parse(@response.body)['note']
      assert_equal @course.price, JSON.parse(@response.body)['old_price']
      assert_equal 90000, new_payment.money
      assert_equal 'pending', new_payment.status
      assert_equal 'cod', new_payment.method
      assert_equal @course.id, new_payment.course_id
      assert_equal 'nguyenduyvu21.02.1995@gmail.com', new_payment.email
      assert_equal 'Nguyễn Duy Vũ', new_payment.name
      assert_equal new_payment.id.to_s, JSON.parse(@response.body)['payment_id']
    end

    it '[JU1007] Should return 200 if user exist , user has not payment of this course' do
      stub_request(:post, /code.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
      post :create_cod_user, {
        :email => @student_user.email,
        :course_id => @course.id,
        :new_price => '99,000'
      }

      new_payment = @assigns['payment']

      assert_response :success
      assert_equal @student_user.id.to_s, JSON.parse(@response.body)['user_id']
      assert_equal 'Tài khoản từ email này đã được user tạo trước đó', JSON.parse(@response.body)['note']
      assert_equal @course.price, JSON.parse(@response.body)['old_price']
      assert_equal 99000, new_payment.money
      assert_equal 'pending', new_payment.status
      assert_equal 'cod', new_payment.method
      assert_equal @course.id, new_payment.course_id
      assert_equal @student_user.email, new_payment.email
      assert_equal new_payment.id.to_s, JSON.parse(@response.body)['payment_id']
    end

    it '[JU1008] Should return 200 if user exist , user has a cancel payment of this course' do
      stub_request(:post, /code.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
      payment = Payment.create(
        :user_id => @student_user.id,
        :course_id => @course.id,
        :method => 'cod',
        :status => 'cancel'
      )

      post :create_cod_user, {
        :email => @student_user.email,
        :course_id => @course.id,
        :new_price => '99,000'
      }

      new_payment = @assigns['payment']

      assert_response :success
      assert_equal @student_user.id.to_s, JSON.parse(@response.body)['user_id']
      assert_equal 'Tài khoản từ email này đã được user tạo trước đó', JSON.parse(@response.body)['note']
      assert_equal @course.price, JSON.parse(@response.body)['old_price']
      assert_equal 99000, new_payment.money
      assert_equal 'pending', new_payment.status
      assert_equal 'cod', new_payment.method
      assert_equal @course.id, new_payment.course_id
      assert_equal @student_user.email, new_payment.email
      assert_equal new_payment.id.to_s, JSON.parse(@response.body)['payment_id']
    end

    it '[JU1009] Should return 200 if user exist , user has a pending payment of this course and get success a cod_code' do
      stub_request(:post, /code.pedia.vn/)
      .to_return(:status => 200, :body => ['{"cod_codes": "[validcod]"}'].join, :headers => {})

      payment = Payment.create(
        :user_id => @student_user.id,
        :course_id => @course.id,
        :method => 'cod',
        :status => 'pending',
        :money => 100000
      )

      post :create_cod_user, {
        :email => @student_user.email,
        :course_id => @course.id,
        :new_price => '99,000'
      }

      new_payment = @assigns['payment']

      assert_response :success
      assert_equal @student_user.id.to_s, JSON.parse(@response.body)['user_id']
      assert_equal 'Tài khoản từ email này đã được user tạo trước đó', JSON.parse(@response.body)['note']
      assert_equal @course.price, JSON.parse(@response.body)['old_price']
      assert_equal 'validcod', JSON.parse(@response.body)['cod_code']
      assert_equal 99000, new_payment.money
      assert_equal 'pending', new_payment.status
      assert_equal 'cod', new_payment.method
      assert_equal @course.id, new_payment.course_id
      assert_equal @student_user.email, new_payment.email
      assert_equal new_payment.id.to_s, JSON.parse(@response.body)['payment_id']
    end

    it '[JU1010] Should return 200 if user exist , user has a pending payment of this course and get fail a cod_code' do
      stub_request(:post, /code.pedia.vn/)
      .to_return(:status => 422, :body => '', :headers => {})

      payment = Payment.create(
        :user_id => @student_user.id,
        :course_id => @course.id,
        :method => 'cod',
        :status => 'pending',
        :money => 100000
      )

      post :create_cod_user, {
        :email => @student_user.email,
        :course_id => @course.id,
        :new_price => '99,000'
      }

      new_payment = @assigns['payment']

      assert_response :success
      assert_equal @student_user.id.to_s, JSON.parse(@response.body)['user_id']
      assert_equal 'Tài khoản từ email này đã được user tạo trước đó', JSON.parse(@response.body)['note']
      assert_equal @course.price, JSON.parse(@response.body)['old_price']
      assert_nil JSON.parse(@response.body)['cod_code']
      assert_equal 99000, new_payment.money
      assert_equal 'pending', new_payment.status
      assert_equal 'cod', new_payment.method
      assert_equal @course.id, new_payment.course_id
      assert_equal @student_user.email, new_payment.email
      assert_equal new_payment.id.to_s, JSON.parse(@response.body)['payment_id']
    end
  end
end