require 'test_helper'

describe 'PaymentController' do
  before do
    stub_request(:get, /tracking.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://flow.pedia.vn:8000/notify/message/create")
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
      .to_return(:status => 200, :body => '', :headers => {})

    @users = User.create([
      {
        email: 'instructor@pedia.vn',
        password: '12345678',
        password_confirmation: '12345678'
      },
      {
        email: 'student@pedia.vn',
        password: '12345678',
        password_confirmation: '12345678'
      }
    ])

    @courses = Course.create([
      {
        name: 'Test combo 1',
        price: 199000,
        alias_name: 'test-combo-course-1',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @users[0]
      },
      {
        name: 'Test combo 2',
        price: 199000,
        alias_name: 'test-combo-course-2',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @users[0]
      },
      {
        name: 'Test combo 3',
        price: 199000,
        alias_name: 'test-combo-course-3',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @users[0]
      }
    ])

    @campaign = Sale::Campaign.create(
      title: 'Test Sale Campaign 1',
      start_date: Time.now,
      end_date: Time.now + 2.days
    )

    @courses[0].curriculums.create(
      status: 0,
      type: "lecture",
      order: 0,
      chapter_index: 0,
      lecture_index: 0,
      object_index: 0,
      title: "Làm giàu có số không các bạn?",
      description: "0:01:11",
      asset_type: "Video",
      url: "http://d3c5ulldcb6uls.cloudfront.net/tu-duy-lam-chu-se-thay-doi-cuoc-doi-ban-nhu-the-nao/bai1master.m3u8",
      previewable: false
    )

    # Sign-in user
    sign_in @users[1]
  end

  after do
    Sale::Campaign.delete_all
    User.delete_all
    Course.delete_all
    Payment.destroy_all
    Tracking.destroy_all
  end

  describe 'GET #index' do
    it 'should redirect to course detail if user already has a pending payment' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        method: Constants::PaymentMethod::COD,
        status: Constants::PaymentStatus::PENDING
      )
      
      get :index, alias_name: @courses[0].alias_name

      assert_response :redirect
      assert_redirected_to "/courses/#{@courses[0].alias_name}/detail"
    end

    it 'should redirect to course learning page if user has a 100%-off coupon' do
      stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_ZERO_AMOUNT_COUPON")
        .to_return(:status => 200,
                  :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_ZERO_AMOUNT_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"max_used": 1',
                    '"course_id": "' + @courses[0].id + '"', 
                    '"discount": 100',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

      get :index, alias_name: @courses[0].alias_name, coupon_code: 'A_ZERO_AMOUNT_COUPON'

      assert_response :redirect
      assert_redirected_to "/home/my-course/select_course?alias_name=#{@courses[0].alias_name}&type=learning"
    end

    it 'should return 404 if user is unable to make a zero amount payment' do

      payment = Payment.create(
        user_id: @users[1].id,
        course_id: @courses[0].id,
        status: Constants::PaymentStatus::SUCCESS
      )

      packages = Sale::Package.create([
        {
          title: 'Test Sale Package 1',
          price: 0,
          campaign: @campaign,
          courses: [@courses[0]],
          participant_count: 2,
          max_participant_count: 10,
          start_date: Time.now,
          end_date: Time.now + 2.days
        }
      ])

      get :index, alias_name: @courses[0].alias_name

      assert_response :missing
    end

    it 'should display index page successfully' do
      get :index, alias_name: @courses[0].alias_name

      course = assigns(:course)
      data = assigns(:data)
      payment = assigns(:payment)

      assert course
      assert_equal payment.money, data[:final_price]
      assert payment
      assert_response :success
    end
  end

  describe 'GET #cod' do
    it 'should redirect to course detail if user already has a pending payment' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        method: Constants::PaymentMethod::COD,
        status: Constants::PaymentStatus::PENDING
      )

      sign_in @users[1]
      
      get :cod, alias_name: @courses[0].alias_name

      assert_response :redirect
      assert_redirected_to "/courses/#{@courses[0].alias_name}/detail"
    end

    it 'should display cod page successfully' do
      get :cod, alias_name: @courses[0].alias_name

      course = assigns(:course)
      data = assigns(:data)

      assert_not_nil course
      assert_not_nil data
      assert_equal course.price, data[:final_price]
      assert_response :success
    end
  end

  describe 'POST #cod' do
    it 'should redirect to course detail if user already has a pending payment' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        method: Constants::PaymentMethod::COD,
        status: Constants::PaymentStatus::PENDING
      )

      post :cod, alias_name: @courses[0].alias_name

      assert_response :redirect
      assert_redirected_to "/courses/#{@courses[0].alias_name}/detail"
    end

    it 'should return 404 if user is unable to make a COD payment' do
      stub_request(:post, "http://code.pedia.vn/cod/create_cod")
        .to_return(
          status: 200,
          body: [
            '{"cod_codes": "[abcdef]"}'
          ].join,
          headers: {}
        )

      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        status: Constants::PaymentStatus::SUCCESS
      )

      post :cod, alias_name: @courses[0].alias_name

      assert_response :missing
    end

    it 'should redirect to payment status page when user successfully made a COD payment' do
      stub_request(:post, 'http://flow.pedia.vn:8000/notify/cod/create')
        .to_return(:status => 200, :body => '', :headers => {})

      stub_request(:post, 'http://code.pedia.vn/cod/create_cod')
        .to_return(
          status: 200,
          body: [
            '{"cod_codes": "[abcdef]"}'
          ].join,
          headers: {}
        )

      post :cod, alias_name: @courses[0].alias_name, name: @users[1].name

      payment = assigns(:payment)

      assert_response :redirect
      assert_redirected_to "/home/payment/#{payment.id.to_s}/status"
    end
  end

  describe 'GET #cancel_cod' do
    before do
      @request.env['HTTP_REFERER'] = 'original_url'
    end

    it 'should redirect user to the previous page if no COD payment is found' do
      get :cancel_cod, course_id: @courses[0].id.to_s

      assert_response :redirect
      assert_redirected_to 'original_url'
    end

    it 'should redirect user to the previous page after cancelling the current COD payment' do
      stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
        .to_return(:status => 200, :body => '', :headers => {})

      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        method: Constants::PaymentMethod::COD,
        status: Constants::PaymentStatus::PROCESS
      )

      @users[1].courses.create(
        course_id: @courses[0].id,
        type: Constants::OwnedCourseTypes::LEARNING,
        payment_status: Constants::PaymentStatus::PENDING,
        created_at: Time.now()
      )

      get :cancel_cod, course_id: @courses[0].id.to_s

      payment = assigns(:payment)

      assert_equal Constants::PaymentStatus::CANCEL, payment.status
      assert_response :redirect
      assert_redirected_to 'original_url'
    end
  end

  describe 'GET #status' do
    it 'should render payment status page successfully' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        money: @courses[0].price,
        status: Constants::PaymentStatus::PENDING
      )

      get :status, id: payment.id.to_s

      assert_response :success
    end

    it 'should render payment status page successfully even when user doesnt have the course' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        money: @courses[0].price,
        status: Constants::PaymentStatus::SUCCESS
      )

      get :status, id: payment.id.to_s

      assert_response :success
    end

    it 'should render payment status page successfully and user course first_learning is false' do
      payment = Payment.create(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        money: @courses[0].price,
        status: Constants::PaymentStatus::SUCCESS
      )

      @users[1].courses.create(
        course_id: @courses[0].id,
        type: Constants::OwnedCourseTypes::LEARNING,
        payment_status: Constants::PaymentStatus::PENDING,
        created_at: Time.now()
      )

      get :status, id: payment.id.to_s

      assert_response :success
      assert_not User.find(@users[1].id).courses.first.first_learning
    end
  end

  describe 'POST #create' do
    it 'should render 422 with error message when payment cannot be saved' do
      post :create, user_id: @users[1].id, course_id: @courses[0].id

      assert_response 422
      assert_equal 'Lỗi không lưu được data:', JSON.parse(@response.body)['message']
    end

    it 'should render payment in JSON format successfully when it is not a COD payment' do
      post :create, {
        user_id: @users[1].id,
        course_id: @courses[0].id,
        method: Constants::PaymentMethod::NONE
      }

      p = JSON.parse(@response.body)

      assert_response :success
      assert_equal Constants::PaymentStatus::SUCCESS, p['status']
      assert_equal 1, Course.find(@courses[0].id).students
    end

    it 'should render payment in JSON format successfully when it is a COD payment' do
      post :create, {
        user_id: @users[1].id,
        course_id: @courses[0].id,
        method: Constants::PaymentMethod::COD
      }

      p = JSON.parse(@response.body)

      assert_response :success
      assert_equal Constants::PaymentStatus::PENDING, p['status']
      assert_equal 0, Course.find(@courses[0].id).students
    end

    it 'should render payment in JSON format successfully when it is a combo' do
      stub_request(:post, "http://mercury.pedia.vn/api/issue/close")
        .to_return(status: 200, body: '', headers: {})

      payment = Payment.create!(
        course_id: @courses[0].id,
        user_id: @users[1].id,
        status: Constants::PaymentStatus::PENDING
      )

      post :create, {
        user_id: @users[1].id,
        course_id: @courses[0].id,
        method: Constants::PaymentMethod::COD,
        is_combo_courses: true
      }

      p = JSON.parse(@response.body)

      assert_response :success
      assert_equal Constants::PaymentStatus::PENDING, p['status']
      assert_equal 0, Course.find(@courses[0].id).students
      assert_equal Constants::PaymentStatus::CANCEL, Payment.find(payment.id).status
    end
  end

  describe 'POST #import_code' do
    it 'should return 404 if cod code invalid' do
      payment = Payment.create(
        :user_id => @users[1].id,
        :course_id => @courses[0].id,
        :status => 'pending',
        :method => 'cod',
        :money => @courses[0].price,
        :cod_code => 'cod_code'
      )

      post :import_code, {
        id: payment.id,
        cod_code: 'INVALID_COD_CODE'
      }

      assert_response 404
      assert_equal 'Mã COD code không hợp lệ!', JSON.parse(response.body)['message']
    end

    it 'should return 200 and create owned_course if user has not owned_course' do
      payment = Payment.create(
        :user_id => @users[1].id,
        :course_id => @courses[0].id,
        :status => 'pending',
        :method => 'cod',
        :money => @courses[0].price,
        :cod_code => 'cod_code'
      )

      post :import_code, {
        id: payment.id,
        cod_code: payment.cod_code
      }

      p = assigns['payment']
      owned_course = p.user.courses.where(:course_id => p.course_id).first

      assert_response :success
      assert_equal 'Thành công!', JSON.parse(response.body)['message']
      assert_not_nil  owned_course
      assert_equal p.status, 'success'
      assert_equal owned_course.payment_status, 'success'
      assert_equal owned_course.type, 'learning'
      assert_equal owned_course.lectures.count, 1
    end

    it 'should return 200 if user has owned_course and save success' do
      payment = Payment.create(
        :user_id => @users[1].id,
        :course_id => @courses[0].id,
        :status => 'pending',
        :method => 'cod',
        :money => @courses[0].price,
        :cod_code => 'cod_code'
      )

      owned_course = @users[1].courses.new(
        course_id: payment.course_id,
        created_at: Time.now()
      )
      owned_course.type = Constants::OwnedCourseTypes::LEARNING
      owned_course.payment_status = Constants::PaymentStatus::PENDING
      UserGetCourseLog.create(course_id: payment.course_id, user_id: @users[1].id, created_at: Time.now())

      payment.course.curriculums
        .where(:type => Constants::CurriculumTypes::LECTURE)
        .map{ |curriculum|
          owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
        }
      owned_course.save


      post :import_code, {
        id: payment.id,
        cod_code: payment.cod_code
      }

      p = assigns['payment']
      owned_course = p.user.courses.where(:course_id => p.course_id).first

      assert_response :success
      assert_equal 'Thành công!', JSON.parse(response.body)['message']
      assert_not_nil  owned_course
      assert_equal p.status, 'success'
      assert_equal owned_course.payment_status, 'success'
      assert_equal owned_course.type, 'learning'
      assert_equal owned_course.lectures.count, 1
    end
  end
end