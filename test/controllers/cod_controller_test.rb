require 'test_helper'

describe 'CodController' do
  before :each do
    stub_request(:get, /tracking.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, /email.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://flow.pedia.vn:8000/notify/message/create")
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
      .to_return(:status => 200, :body => '', :headers => {})

    @instructor_user = User.create(
      email: 'nguyendanhtu@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )
    instructor_profiles = User::InstructorProfile.create([
      {
        academic_rank: 'Doctor',
        user: @instructor_user
      }
    ])

    @course = Course.create({
      name: 'A test course',
      lang: 'vi', 
      price: 699000,
      old_price: 0, 
      alias_name: 'test-course', 
      sub_title: 'Login 5 website using CURL PHP gfd', 
      description: ['Mô tả về khóa học', 'Login 5 website using CURL PHP'], 
      requirement: ['Yêu cầu của khóa học', 'Login 5 website using CURL PHP'], 
      benefit: ['Lợi ích từ khóa học', 'Login 5 website using CURL PHP'], 
      audience: ['Đối tượng mục tiêu', 'Login 5 website using CURL PHP'], 
      labels_order: [], 
      related: [], 
      enabled_logo: true, 
      enabled: true, 
      level: 'all', 
      image: '/uploads/images/courses/course_image_bgfold1.jpg', 
      intro_link: '', 
      intro_image: '/uploads/images/courses/thumbnail_sale.png', 
      version: 'public', 
      user_id: @instructor_user.id, 
      category_ids: [], 
      label_ids: [],
      curriculums: [
        {
          "_id"=>'5629f193df52b90ecc000009',
          "asset_type"=>"Video",
          "chapter_index"=>0,
          "description"=>"",
          "lecture_index"=>0,
          "object_index"=>0,
          "order"=>0,
          "status"=>0,
          "title"=>"P1",
          "type"=>"chapter",
          "url"=>""
        }
      ]
    })

    @user = User.create!({
      email: 'user1123@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'user'
    })

    @other_user = User.create!({
      email: 'user5813@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'user'
    })

    @user.courses.create!({
      course_id: @course.id,
      type: 'learning',
      payment_status: 'pending',
    })

    @payment = Payment.create!({
      user_id: @user.id,
      course_id: @course.id,
      method: 'cod',
      status: Constants::PaymentStatus::PENDING,
      cod_code: 'ABCFED123AWESOME'
    })
  end

  after :each do
    Payment.delete_all
    Course.delete_all
    User.delete_all
    Contactc3.delete_all
  end

  it 'should get activate' do
    get :activate

    assert_response :success
    assert_match 'Kích hoạt', response.body
  end

  it 'should patch activate' do
    patch :activate

    assert_response :success
    assert_match 'Kích hoạt', response.body
  end

  it 'should alert when COD cod is empty' do
    patch :activate

    assert_response :success
    assert_match 'Vui lòng nhập mã COD để kích hoạt', response.body
  end

  it 'should alert when COD code does not exist' do
    patch :activate, cod_code: 'Not a COD code'

    assert_response :success
    assert_match 'Mã COD không hợp lệ', response.body
  end

  it 'should alert when COD code is already activated and user is not logged in' do
    @payment.status = Constants::PaymentStatus::SUCCESS
    @payment.save
    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Mã COD đã được kích hoạt', response.body
    assert_match 'Vui lòng kiểm tra danh sách khóa học của bạn tại', response.body
  end

  it 'should alert when COD code is activated & user logged in & not user course' do
    @payment.status = Constants::PaymentStatus::SUCCESS
    @payment.save

    sign_in :user, @other_user

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Mã COD này không thuộc về tài khoản bạn đang đăng nhập', response.body
  end

  it 'should alert when COD code is activated & user logged in & is user course' do
    @payment.status = Constants::PaymentStatus::SUCCESS
    @payment.save

    sign_in :user, @user

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Mã COD đã được kích hoạt. Bạn có thể vào học', response.body
  end

  it 'should render success when COD cod is valid' do
    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Kích hoạt thành công',  response.body
    assert_match 'Vào học ngay',  response.body
    assert_match @course.name, response.body
    assert_match @course.image, response.body
  end

  it 'should update payment & user' do
    patch :activate, cod_code: @payment.cod_code

    assert_response :success

    @payment.reload
    @user.reload
    owned_course = @user.courses.where(course_id: @course.id).first
    assert_not owned_course.nil?
    assert_equal Constants::PaymentStatus::SUCCESS, @payment.status
    assert_equal Constants::PaymentStatus::SUCCESS, owned_course.payment_status
  end

  it 'should show email & password when password is 12345678' do
    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match @user.email, response.body
    assert_match '12345678', response.body
  end

  it 'should not show email & password when password is not 12345678' do
    @user.update(password: 'abcdefgh', password_confirmation: 'abcdefgh')
    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_no_match @user.email, response.body
    assert_no_match 'Password', response.body
  end

  it 'should not show email & password when it is not the first course' do
    @user.courses.create!({
      course_id: @course.id,
      type: 'learning',
      payment_status: 'success',
    })

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_no_match @user.email, response.body
    assert_no_match 'Password', response.body
  end

  it 'should catch system error when payment\'s user has no owned course' do
    @user.courses.delete_all

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Có lỗi với đơn hàng của bạn', response.body
  end

  it 'should catch system error when payment has no user' do
    @user.delete

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Có lỗi với đơn hàng của bạn', response.body
  end

  it 'should catch system error when payment has no course' do
    @course.delete

    patch :activate, cod_code: @payment.cod_code

    assert_response :success
    assert_match 'Có lỗi với đơn hàng của bạn', response.body
  end

  it 'should create contact c3 crosssale native when user ok' do 
    patch :activate, cod_code: @payment.cod_code, is_subscribe_native: 'true'

    contactc3 = Contactc3.where(type: "c3_crosssell_native_l8").first
    assert_not_nil contactc3
  end

  it 'should not create c3 crosssale native when user dont check' do 
    patch :activate, cod_code: @payment.cod_code

    contactc3 = Contactc3.where(type: "c3_crosssell_native_l8").first
    assert_nil contactc3
  end 
end