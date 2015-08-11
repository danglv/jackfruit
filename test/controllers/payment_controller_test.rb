require 'test_helper'

class PaymentControllerTest < ActionController::TestCase
  def setup
    @user = User.create(name: "test_user", email: "test@gmail.com", password: "123456")
    @user.save

    @course = Course.create(:name => 'Test course 1', 'alias_name' => 'test-course-1', 'lang' => Constants::CourseLang::EN)
    curriculums = [
      Course::Curriculum.new(type: Constants::CurriculumTypes::CHAPTER, asset_type: Constants::CurriculumAssetTypes::SLIDE, title: 'test-course-1-chapter-1'),
      Course::Curriculum.new(type: Constants::CurriculumTypes::LECTURE, asset_type: Constants::CurriculumAssetTypes::SLIDE, title: 'test-course-1-lecture-1')
    ]
    @course.curriculums = curriculums
    @course.enabled = true
    @course.version = Constants::CourseVersions::PUBLIC
    @course.save
  end

  def teardown
    @user.destroy
    @course.destroy
    Payment.all.destroy
  end

  test 'in payment/index page, unauthenticated user will be redirected to users/sign_in' do
    get 'index', {alias_name: 'test-course-1'}
    assert_response :redirect
    assert_match /users\/sign_in/, @response.redirect_url
  end

  test 'in payment/index page, authenticated user will get success response' do    
    sign_in :user, @user
    get 'index', {alias_name: 'test-course-1'}
    assert_response :success
  end

  test 'in payment/index page, request with invalid course alias name will get 404 response' do
    sign_in :user, @user
    get :index, {alias_name: 'an-invalid-course'}
    assert_response :missing
  end

  test 'in payment/cod page, request with invalid course alias name will get 404 response' do
    sign_in :user, @user
    get :cod, {alias_name: 'an-invalid-course'}
    assert_response :missing
  end

  test 'in payment/cod, submission with valid info will be redirected to payment/pending page' do
    sign_in :user, @user
    data = {
      :alias_name => 'test-course-1',
      :name => @user.name,
      :email => @user.email,
      :mobile => '123456',
      :address => 'Test Address',
      :city => 'HN',
      :district => 'HK'
    }
    post :cod, data

    course = Course.where(:id => @course.id).first
    owned_course = User.where(:id => @user.id).first.courses.where(course_id: @course.id).first

    assert_not owned_course.blank?
    assert_equal 1, owned_course.lectures.size
    assert_equal Constants::OwnedCourseTypes::LEARNING, owned_course.type
    assert_equal Constants::PaymentStatus::PENDING, owned_course.payment_status

    assert_equal 1, course.students

    assert_response :redirect
    assert_match /pending/, @response.redirect_url
  end

  test 'in payment/online_payment, authenticated user will be redirected to baokim services' do
    sign_in :user, @user
    get 'online_payment', {alias_name: 'test-course-1', p: 'baokim'}

    course = Course.where(:id => @course.id).first
    current_user = User.where(:id => @user.id).first
    owned_course = current_user.courses.where(course_id: @course.id).first

    assert_not owned_course.blank?
    assert_equal 1, owned_course.lectures.size
    assert_equal Constants::OwnedCourseTypes::LEARNING, owned_course.type
    assert_equal Constants::PaymentStatus::PENDING, owned_course.payment_status

    assert_equal 1, course.students
    assert_equal 1, current_user.courses.size

    assert_response :redirect
    assert_match /merchant_id/, @response.redirect_url
    assert_match /order_id/, @response.redirect_url
    assert_match /business/, @response.redirect_url
    assert_match /total_amount/, @response.redirect_url
    assert_match /shipping_fee/, @response.redirect_url
    assert_match /tax_fee/, @response.redirect_url
    assert_match /order_description/, @response.redirect_url
    assert_match /url_success/, @response.redirect_url
    assert_match /url_cancel/, @response.redirect_url
    assert_match /url_detail/, @response.redirect_url
    assert_match /checksum/, @response.redirect_url
  end

  test 'in payment/success, request from baokim with valid checksum will update a payment as success' do
    sign_in :user, @user
    get 'online_payment', {alias_name: 'test-course-1', p: 'baokim'}

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    redirect_url = @response.redirect_url

    params = CGI::parse(URI::parse(@response.redirect_url).query)
    params.map { |k, v| params[k] = v[0]  }
    params['id'] = payment.id.to_s
    params['p'] = 'baokim'

    get 'success', params

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    owned_course = User.where(:id => @user.id).first.courses.where(course_id: @course.id).first

    assert_equal Constants::PaymentStatus::SUCCESS, owned_course.payment_status
    assert_response :success
  end

  test 'in payment/success, request from baokim with invalid checksum will get error response' do
    sign_in :user, @user
    get 'online_payment', {alias_name: 'test-course-1', p: 'baokim'}

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    redirect_url = @response.redirect_url

    params = CGI::parse(URI::parse(@response.redirect_url).query)
    params.map { |k, v| params[k] = v[0]  }
    params['id'] = payment.id.to_s
    params['p'] = 'baokim'
    params['checksum'] = 'invalid'

    get 'success', params

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    owned_course = User.where(:id => @user.id).first.courses.where(course_id: @course.id).first

    assert_equal Constants::PaymentStatus::PENDING, owned_course.payment_status
    assert_response :missing
  end

  test 'in payment/cancel, request from baokim with valid checksum will update a payment as cancelled' do
    sign_in :user, @user
    get 'online_payment', {alias_name: 'test-course-1', p: 'baokim'}

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    redirect_url = @response.redirect_url

    params = CGI::parse(URI::parse(@response.redirect_url).query)
    params.map { |k, v| params[k] = v[0]  }
    params['id'] = payment.id.to_s
    params['p'] = 'baokim'

    get 'cancel', params

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    owned_course = User.where(:id => @user.id).first.courses.where(course_id: @course.id).first

    assert_equal Constants::PaymentStatus::CANCEL, owned_course.payment_status
    assert_response :success
  end

  test 'in payment/cancel, request from baokim with invalid checksum will get error response' do
    sign_in :user, @user
    get 'online_payment', {alias_name: 'test-course-1', p: 'baokim'}

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    redirect_url = @response.redirect_url

    params = CGI::parse(URI::parse(@response.redirect_url).query)
    params.map { |k, v| params[k] = v[0]  }
    params['id'] = payment.id.to_s
    params['p'] = 'baokim'
    params['checksum'] = 'invalid'

    get 'cancel', params

    payment = Payment.where(:user_id => @user.id, :course_id => @course.id).first
    owned_course = User.where(:id => @user.id).first.courses.where(course_id: @course.id).first

    assert_equal Constants::PaymentStatus::PENDING, owned_course.payment_status
    assert_response :missing
  end
end
