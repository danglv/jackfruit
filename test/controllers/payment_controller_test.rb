require 'test_helper'

describe 'PaymentController' do
  before do
    stub_request(:get, /tracking.pedia.vn/)
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

    # Sign-in user
    sign_in @users[1]
  end

  after do
    @users.each { |x| x.destroy }
    @courses.each { |x| x.destroy }
    @campaign.destroy
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
  end
end