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

  test 'in payment/cod, submission with valid info will be redirected to payment/status page' do
    sign_in :user, @user
    data = {
      :alias_name => 'test-course-1',
      :is_submitted => true,
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
    assert_match /status/, @response.redirect_url
  end
end
