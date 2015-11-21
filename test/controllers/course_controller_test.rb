require 'test_helper'

describe 'CoursesController' do
  before :each do

    stub_request(:get, /.*tracking.pedia.vn.*/)
      .to_return(:status => 200, :body => '')

    stub_request(:post, /flow.pedia.vn/)
      .to_return(:status => 200, :body => '')

    stub_request(:post, "#{FLOW_BASE_API_URL}/wasp/feedback/create")
    	.to_return(:status => 200, :body => '')

    @coupon_code = 'KHANHDN'
    @res_coupon = '{"_id":"56363fe48e62a4142f0000a3","coupon":"KHANHDN","created_at":"2015-11-01T16:37:56.232Z","expired_date":"2015-12-30T17:00:00.000Z","course_id":"560b4e96eb5d8904c1000002","used":0,"enabled":true,"max_used":1,"discount":100.0,"return_value":"100","issued_by":"560b4e95eb5d8904c1000000"}'
    @res_coupon_invalid = '{"message":"Mã coupon không tồn tại"}'

    @users = User.create([
      {
        _id: '56122655df52b90f8a000012',
        email: 'test_account_1@gmail.com',
        password: '12345678',
        password_confirmation: '12345678',
        role: 'user'
      },
      {
        email: 'test_account_2@gmail.com',
        password: '12345678',
        password_confirmation: '12345678',
        role: 'test'
      },
      {
        email: 'test_account_3@gmail.com',
        password: '12345678',
        password_confirmation: '12345678',
        role: 'reviewer'
      },
      {
        email: 'cskh@pedia.vn',
        password: '12345678'
      }
    ])

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

    @user_role_user = User.create(
      email: 'user_role_user@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'user'
    )

    @test_role_user = User.create(
      email: 'test_role_user@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'test'
    )

    @reviewer_role_user = User.create(
      email: 'reviewer_role_user@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'reviewer'
    )

    @params = {
      user_id: '56122655df52b90f8a000012',
      course_id: '5613bae6df52b91d11000007',
      course: ''
    }
    
    @courses = Course.create([
      {
        _id: '5613bae6df52b91d11000007',
        name: 'Login 5 website using CURL PHP - Thanh Nguyễn ',
        lang: 'vi',
        price: 699000,
        old_price: 0,
        alias_name: 'login-5-website-using-curl-php',
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
      },
      {
        name: 'Test Course Version',
        alias_name: 'test_course',
        price: 699000,
        enabled: true,
        version: 'test',
        user_id: @instructor_user.id
      },
      {
        name: 'Free Course',
        alias_name: 'free_course',
        price: 0,
        enabled: true,
        version: 'public',
        user_id: @instructor_user.id
      },
      {
        name: 'Disable Course',
        alias_name: 'disable_course',
        price: 0,
        enabled: false,
        version: 'public',
        user_id: @instructor_user.id
      }
    ])
    
    @versions = Course::Version.create([
      {
        version_course: '1.5',
        name: 'New Version',
        lang: 'vi',
        alias_name: 'new-version-15',
        sub_title: 'Login 5 website using CURL PHP gfd',
        description: ['Mô tả về khóa học', 'Login 5 website using CURL PHP'],
        requirement: ['Yêu cầu của khóa học', 'Login 5 website using CURL PHP'],
        benefit: ['Lợi ích từ khóa học', 'Login 5 website using CURL PHP'],
        audience: ['Đối tượng mục tiêu', 'Login 5 website using CURL PHP'],
        level: 'all',
        image: '/uploads/images/courses/course_image_bgfold1.jpg',
        intro_link: '',
        intro_image: '/uploads/images/courses/thumbnail_sale.png',
        user_id: @instructor_user.id,
        course_id: @courses[0].id,
        category_ids: [],
        label_ids: []
      }
    ])

    @category = Category.create(
      _id: 'test-category',
      name: 'Test Category',
      alias_name: 'test-category',
      enabled: true
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

    @discussion = @courses.first.discussions.create(
      title: "Cần trợ giúp",
      description: "Tôi không xem được video",
      user_id: @users[0].id
    )

    @child_discussion = @discussion.child_discussions.create(
      description: "Mình cũng không xem được video",
      user_id: @users[0].id
    )

    @parent_announcement = @courses.first.announcements.create(
      title: 'Thông báo tạm dừng khoá học',
      description: 'Éo bán nữa',
      user_id: @courses.first.user_id
    )

    @child_announcement = @parent_announcement.child_announcements.create(
      description: 'Trả lại tiền đê',
      user_id: @users.first.id
    )
  end

  after :each do
    User.delete_all
    Course.delete_all
    Category.delete_all
    Course::Version.delete_all
  end

  describe 'GET #index' do
    # labels = Label.create([
    #   {
    #     _id: Constants::Labels::FEATURED,
    #     name: Constants::Labels::FEATURED
    #   },
    #   {
    #     _id: Constants::Labels::TOP_PAID,
    #     name: Constants::Labels::TOP_PAID
    #   },
    #   {
    #     _id: Constants::Labels::TOP_FREE,
    #     name: Constants::Labels::TOP_FREE
    #   }
    # ])

    # courses = Course.create([
    #   {
    #     name: 'Course Label Featured',
    #     alias_name: 'course_label_featured',
    #     price: 699000,
    #     enabled: true,
    #     version: 'public',
    #     user_id: @instructor_user.id,
    #     label_ids: [labels[0].id]
    #   },
    #   {
    #     name: 'Course Label TOP PAID',
    #     alias_name: 'course_label_top_paid',
    #     price: 699000,
    #     enabled: true,
    #     version: 'public',
    #     user_id: @instructor_user.id,
    #     label_ids: [labels[1].id]
    #   },
    #   {
    #     name: 'Course Label TOP Free',
    #     alias_name: 'course_label_top_free',
    #     price: 0,
    #     enabled: true,
    #     version: 'public',
    #     user_id: @instructor_user.id,
    #     label_ids: [labels[2].id]
    #   },
    #   {
    #     name: 'Course Label Featured',
    #     alias_name: 'course_label_featured',
    #     price: 699000,
    #     enabled: true,
    #     version: 'test',
    #     user_id: @instructor_user.id,
    #     label_ids: [labels[0].id]
    #   }
    # ])

    it '[JC101] not authenticated, should has all public courses follow labels' do
      get :index

      result_courses = assigns(:courses)

      assert_response :success
    end
  end

  describe 'GET #list_course_feature' do
    it 'success when visit courses/list_course_featured' do
      get :list_course_featured, {
        :category_alias_name => @category.id
      }

      assert_response :success
    end
  end

  describe 'GET #list_course_all' do
    it 'success when visit courses/list_course_all' do
      get :list_course_all, {
        :category_alias_name => @category.id
      }

      assert_response :success
    end

    it 'show all public course have category_id == test-category' do
      @courses.each do |course|
        course.category_ids = [@category.id]
        course.save
      end

      get :list_course_all, {
        :category_alias_name => @category.id
      }

      courses = assigns(:courses)

      assert_response :success
      assert courses.include?(@courses[0])
      assert !courses.include?(@courses[1])
      assert courses.include?(@courses[2])
      assert !courses.include?(@courses[3])
    end

    it 'show all public course have category_id == test-category and free if budget if price is 0' do
      @courses.each do |course|
        course.category_ids = [@category.id]
        course.save
      end

      get :list_course_all, {
        :category_alias_name => @category.id,
        :budget => Constants::BudgetTypes::FREE
      }

      courses = assigns(:courses)

      assert_response :success
      assert !courses.include?(@courses[0])
      assert !courses.include?(@courses[1])
      assert courses.include?(@courses[2])
      assert !courses.include?(@courses[3])
    end

    it 'show all public course have category_id == test-category and paid if budget if price is greater than 0' do
      @courses.each do |course|
        course.category_ids = [@category.id]
        course.save
      end

      get :list_course_all, {
        :category_alias_name => @category.id,
        :budget => Constants::BudgetTypes::PAID
      }

      courses = assigns(:courses)

      assert_response :success
      assert courses.include?(@courses[0])
      assert !courses.include?(@courses[1])
      assert !courses.include?(@courses[2])
      assert !courses.include?(@courses[3])
    end
  end

  describe 'GET #detail' do
    it '[JC401] not authenticated, success when go to public courses' do
      get :detail, {
        :alias_name => @courses[0].alias_name
      }

      assert_response :success
    end

    it '[JC402] not authenticated, missing when go to test courses' do
      get :detail, {
        :alias_name => @courses[1].alias_name
      }
      assert_response :missing
    end

    it '[JC403] not authenticated, missing when go to disable courses' do
      get :detail, {
        :alias_name => @courses[3].alias_name
      }
      assert_response :missing
    end

    it '[JC405] authenticated, missing when go to public course detail if course is disable, role user is user' do
      sign_in @user_role_user

      get :detail, {
        :alias_name => 'disable_course'
      }
      assert_response :missing
    end

    it '[JC406] authenticated, missing when go to test course detail if course has enabled, role user is user' do
      sign_in @user_role_user

      get :detail, {
        :alias_name => 'test_course'
      }

      assert_response :missing
    end

    it '[JC409] authenticated, not redirect to learning if preview is expired' do
      @user_role_user.courses.create(
        :type => Constants::OwnedCourseTypes::PREVIEW,
        :course_id => @courses[0].id,
        :expired_at => Time.now - 1.minutes,
        :payment_status => Constants::PaymentStatus::PENDING
      )

      sign_in @user_role_user

      get :detail, {
        :alias_name => @courses[0].alias_name
      }

      assert_response :success
    end

    it '[JC410] authenticated, redirect to learning if preview is not expired' do
      @user_role_user.courses.create(
        :type => Constants::OwnedCourseTypes::PREVIEW,
        :course_id => @courses[0].id,
        :expired_at => Time.now + 5.minutes,
        :payment_status => Constants::PaymentStatus::PENDING
      )

      sign_in @user_role_user

      get :detail, {
        :alias_name => @courses[0].alias_name
      }

      assert_response :redirect
      assert_redirected_to "/courses/#{@courses[0].alias_name}/learning"
    end

    it '[JC411] authenticated, redirect to learning if user bought course' do
      @user_role_user.courses.create(
        :type => Constants::OwnedCourseTypes::LEARNING,
        :course_id => @courses[0].id,
        :payment_status => Constants::PaymentStatus::SUCCESS
      )

      sign_in @user_role_user

      get :detail, {
        :alias_name => @courses[0].alias_name
      }

      assert_response :redirect
      assert_redirected_to "/courses/#{@courses[0].alias_name}/learning"
    end

    it '[JC412] authenticated, not redirect to learning if user not has course' do
      @user_role_user.courses = []
      @user_role_user.save

      sign_in @user_role_user

      get :detail, {
        :alias_name => @courses[0].alias_name
      }

      assert_response :success
    end

    it 'should have @course is a version with version_course is params[:version]' do
      sign_in @reviewer_role_user

      get :detail, {
        version: @versions[0].version_course,
        alias_name: @versions[0].alias_name
      }

      assert_equal @versions[0].alias_name, assigns[:course][:alias_name]  
    end
    
    it 'should save session to review for learning, lecture when have params[:version]' do
      sign_in @reviewer_role_user

      get :detail, alias_name: 'blabla', version: @versions[0].version_course

      assert_equal session[:version], @versions[0].version_course
    end 

    it 'should render 404 when version of course not found' do
      sign_in @reviewer_role_user

      get :detail, alias_name: 'blabla'

      assert_response 404
    end

    it 'should have @course is a course not version of course when user isnt reviewer' do 
      sign_in @user_role_user

      get :detail, alias_name: @courses[0].alias_name, version: '1.0'

      assert_nil session[:version]
      assert_not_nil assigns[:course]
      assert_equal @courses[0].alias_name, assigns[:course][:alias_name]
    end
  end

  describe 'GET #get_money' do
    it 'should render 422 and message when course_id is blank' do
      get :get_money
      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'chưa truyền dữ course_id', res['message']
    end

    it 'should render 422 and message when course not found' do
      stub_request(:get, "http://code.pedia.vn/coupon?coupon=#{@coupon_code}").
        to_return(:status => 200, :body => @res_coupon)

      get :get_money, {
        course_id: 'blabla',
        coupon_code: @coupon_code
      }
      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'course_id không chính xác', res['message']
    end

    it 'should render success and price is 0 when check coupon_code has discount 100%' do
      stub_request(:get, "http://code.pedia.vn/coupon?coupon=#{@coupon_code}").
        to_return(:status => 200, :body => @res_coupon)
      get :get_money, {
        course_id: @courses[0]['id'],
        coupon_code: @coupon_code
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_match 'price', res.to_s
      assert_match '0', res.to_s
    end

    it 'should render success and price is current price when invalid coupon_code' do
      stub_request(:get, /code.pedia.vn/).
        to_return(:status => 422, :body => @res_coupon_invalid)
      get :get_money, {
        course_id: @courses[0]['id'],
        coupon_code: @coupon_code
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_match 'price', res.to_s
      assert_match "#{@courses[0].price}", res.to_s
    end
  end

  describe "POST #upload_image" do
    it 'should return image path' do

    end

    it 'should return error when have exception' do
      post :upload_image, {
        image: 'image',
        file_name: 'blabla'
      }

      res = JSON.parse(response.body)

      assert_match 'Có lỗi xảy ra', res['error']
    end
  end

  describe "POST #upload_document" do
    it 'should return document when success' do

    end

    it 'should return error when have exception' do
      post :upload_document, {
        file: 'file',
        file_name: 'file_name'
      }

      res = JSON.parse(response.body)

      assert_match 'Có lỗi xảy ra', res['error']
    end
  end

  describe "POST #add_discussion" do
    it 'should return 422 if description is blank' do
    	sign_in @users[0]
      post :add_discussion, {
        id: @courses.first.id
      }

      assert_response :unprocessable_entity
      assert_match 'Nội dung không được để trống', response.body
    end

    it 'should return 422 if course not exist' do
    	sign_in @users[0]
      post :add_discussion, {
        id: 'INVALIDE_COURSE_ID',
        description: 'This is description'
      }

      assert_response :unprocessable_entity
      assert_match 'Khoá học không tồn tại!', response.body
    end

    it 'should return 200 if user post a parent discussion' do
      sign_in @users[0]
      post :add_discussion, {
        id: @courses[0].id,
        title: 'This is title',
        description: 'This is description'
      }

      discussion = assigns[:discussion]

      assert_response :success
      assert_match 'This is title', response.body
      assert_match 'This is description', response.body
      assert_match @users[0].email, response.body
      assert_equal discussion.child_discussions.count, 0
      assert_equal discussion.course.id, @courses[0].id
      assert_equal discussion.user_id, @users[0].id
      assert_equal discussion.curriculum_id.blank?, true
    end

     it 'should return 200 if user post a parent discussion at lecture' do
      sign_in @users[0]
      post :add_discussion, {
        id: @courses[0].id,
        title: 'This is title',
        description: 'This is description',
        curriculum_id: @courses[0].curriculums[1].id.to_s
      }

      discussion = assigns[:discussion]

      assert_response :success
      assert_match 'This is title', response.body
      assert_match 'This is description', response.body
      assert_match @users[0].email, response.body
      assert_equal discussion.child_discussions.count, 0
      assert_equal discussion.course.id, @courses[0].id
      assert_equal discussion.user_id, @users[0].id
      assert_equal discussion.curriculum_id, @courses[0].curriculums[1].id.to_s
    end

    it 'should return 200 if user post a child discussion at learning' do
      sign_in @users[0]

      post :add_discussion, {
        id: @courses[0].id,
        title: 'This is title',
        description: 'This is description',
        parent_discussion: @discussion.id
      }

      discussion = assigns[:discussion]

      assert_response :success
      assert_match 'This is title', response.body
      assert_match 'This is description', response.body
      assert_match @users[0].email, response.body
      assert_equal discussion.parent_discussion.id, @discussion.id
      assert_equal discussion.parent_discussion.course.id, @courses[0].id
      assert_equal discussion.user_id, @users[0].id
      assert_equal discussion.parent_discussion.curriculum_id, ''
    end

    it 'should return 200 if user post a child discussion at lecture' do
      sign_in @users[0]

      parent_discussion_lecture = @courses.first.discussions.create(
        description: 'This is description',
        curriculum_id: @courses[0].curriculums[1].id.to_s,
        user_id: @users[0].id
      )

      post :add_discussion, {
        id: @courses[0].id,
        title: 'This is title',
        description: 'This is description',
        parent_discussion: parent_discussion_lecture.id
      }

      discussion = assigns[:discussion]

      assert_response :success
      assert_match 'This is title', response.body
      assert_match 'This is description', response.body
      assert_match @users[0].email, response.body
      assert_equal discussion.parent_discussion.id, parent_discussion_lecture.id
      assert_equal discussion.parent_discussion.course.id, @courses[0].id
      assert_equal discussion.user_id, @users[0].id
      assert_equal discussion.parent_discussion.curriculum_id, parent_discussion_lecture.curriculum_id
      assert_equal discussion.parent_discussion.curriculum_id, @courses[0].curriculums[1].id.to_s
    end
  end

  describe "POST #add_discussion_from_wasp" do
    it 'Should return message error when param parent_discussion blank' do
      post :add_discussion_from_wasp, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '',
        description: '1343'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "parent_discussion không được bỏ trống!", res['message']
    end

    it 'Should return message error when param description blank' do
      post :add_discussion_from_wasp, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23984',
        description: ''
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "description không được bỏ trống!", res['message']
    end

    it 'Should return message error when invalid course' do
      post :add_discussion_from_wasp, {
        id: 'invalid_course',
        parent_discussion: '23984',
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Khóa học không hợp lệ", res['message']
    end

    it 'Should return message error when invalid parent_discussion' do
      post :add_discussion_from_wasp, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23984',
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Parrent discussion không tồn tại", res['message']
    end

    it 'Should return message error when discussion not save' do
      post :add_discussion_from_wasp, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23984',
        description: 123
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
    end

    it 'Should return message error when discussion save success' do
      post :add_discussion_from_wasp, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: @discussion._id,
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response 200
      assert_equal "success", res['message']
    end
  end

  describe "POST #edit_discussion" do
    it 'Should return message error when param parent_discussion blank' do
      post :edit_discussion, {
        id: '5613bae6df52b91d11000007',
        discussion_id: '1234',
        description: '1343'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "parent_discussion không được bỏ trống!", res['message']
    end

    it 'Should return message error when param discussion_id blank' do
      post :edit_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23984',
        description: '1343'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "discussion_id không được bỏ trống!", res['message']
    end

    it 'Should return message error when param description blank' do
      post :edit_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23984',
        discussion_id: '1234'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "description không được bỏ trống!", res['message']
    end

    it 'Should return message error when invalid course' do
      post :edit_discussion, {
        id: 'invalid_course',
        parent_discussion: '23984',
        discussion_id: '1234',
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Khóa học không hợp lệ", res['message']
    end

    it 'Should return message error when invalid discussion' do
      post :edit_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: @discussion._id,
        discussion_id: '68234762',
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Không tồn tại thảo luận này", res['message']
    end

    it 'Should return message success when description valid' do
      post :edit_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: @discussion._id,
        discussion_id: @child_discussion._id,
        description: 'test'
      }

      res = JSON.parse(response.body)

      assert_response 200
      assert_equal "Sửa thành công", res['message']
    end
  end

  describe "POST #delete_discussion" do
    it 'Should return message error when param parent_discussion blank' do
      post :delete_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '',
        discussion_id: '1234'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "parent_discussion không được bỏ trống", res['message']
    end

    it 'Should return message error when param discussion_id blank' do
      post :delete_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '23423',
        discussion_id: ''
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "discussion_id không được bỏ trống", res['message']
    end

    it 'Should return message error when param invalid_course' do
      post :delete_discussion, {
        id: 'invalid_course',
        parent_discussion: '23423',
        discussion_id: '1212324'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Khóa học không hợp lệ", res['message']
    end

    it 'Should return message error when param invalid discussion' do
      post :delete_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: '1212324',
        discussion_id: 'invalid_discussion'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Không tồn tại thảo luận này", res['message']
    end

    it 'Should return message ok when discussion valid' do
      post :delete_discussion, {
        id: '5613bae6df52b91d11000007',
        parent_discussion: @discussion._id,
        discussion_id: @child_discussion._id
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Không tồn tại thảo luận này", res['message']
    end
  end

  describe "POST #add_announcement" do
    it 'Should return error when param description blank' do
      sign_in @users[0]

      post :add_announcement, {
        id: @courses[0].id,
        title: 'This is title'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Description không được bỏ trống!", res['error']
    end

    it 'Should return message error when invalid course' do
      sign_in @users[0]

      post :add_announcement, {
        id: 'INVALID_COURSE_ID',
        title: 'This is title',
        description: 'This is description'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Khoá học không tồn tại!", res['error']
    end

    it 'Should return message error when current_user is not author' do
      sign_in @users[0]

      post :add_announcement, {
        id: @courses[0].id,
        title: 'This is title',
        description: 'This is description'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Tài khoản đang đăng nhập không sở hữu khoá học này!', res['error']
    end

    it 'Should return 200 if current_user is author' do
      sign_in @instructor_user

      post :add_announcement, {
        id: @courses[0].id.to_s,
        title: 'This is title',
        description: 'This is description'
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_equal 'This is title', res['title']
      assert_equal 'This is description', res['description']
      assert_equal @instructor_user.email, res['email']
      assert_equal @instructor_user.name, res['name']
      assert_equal @instructor_user.avatar, res['avatar']
    end
  end

  describe "POST #add_child_announcement" do
    it 'Should return error when param description blank' do
      sign_in @users[0]

      post :add_child_announcement, {
        id: @courses[0].id,
        parent_announcement_id: @parent_announcement.id
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Description không được bỏ trống!", res['error']
    end

    it 'Should return error when param parent_announcement blank' do
      sign_in @users[0]

      post :add_child_announcement, {
        id: @courses[0].id,
        description: 'This is description'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "parent_announcement_id không được bỏ trống!", res['error']
    end

    it 'Should return message error when invalid course' do
      sign_in @users[0]

      post :add_child_announcement, {
        id: 'INVALID_COURSE_ID',
        description: 'This is description',
        parent_announcement_id: @parent_announcement.id
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Khoá học không tồn tại!", res['error']
    end

    it 'Should return message error when parent_announcement is not exist' do
      sign_in @users[0]

      post :add_child_announcement, {
        id: @courses[0].id,
        description: 'This is description',
        parent_announcement_id: 'INVALID_PARENT_ANNOUNCEMENT_ID'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Thông báo không tồn tại!', res['error']
    end

    it 'Should return 200 if current_user create child_announcement is success' do
      sign_in @users[0]

      post :add_child_announcement, {
        id: @courses[0].id,
        description: 'This is description',
        parent_announcement_id: @parent_announcement.id
      }

      res = JSON.parse(response.body)
      child_announcement = assigns['child_announcement']

      assert_response :success
      assert_equal 'This is description', res['description']
      assert_equal @users[0].email, res['email']
      assert_equal @users[0].name, res['name']
      assert_equal @users[0].avatar, res['avatar']
      assert_equal child_announcement.parent_announcement.id, @parent_announcement.id
      assert_equal child_announcement.parent_announcement.course.id, @courses[0].id
    end
  end

  describe 'POST #activate' do
    it 'should show user an error when activation code is invalid' do
      activate_code = 'AN_INVALID_ACTIVATION_CODE'
    
      stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{activate_code}")
        .to_return(status: 422,
          body: '{"message": "Mã cod không tồn tại"}',
          headers: {}
        )

      post :activate, activation_code: activate_code

      assert_response :success
      assert_equal 'Mã kích hoạt không hợp lệ, vui lòng thử lại', assigns('error')
    end

    it 'should show user no error when activation code is valid' do
      activate_code = 'A_VALID_ACTIVATION_CODE'
    
      stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{activate_code}")
        .to_return(status: 200,
          body: '{"message": "Mã cod không tồn tại"}',
          headers: {}
        )

      post :activate, activation_code: activate_code

      assert_response :success
      assert_nil assigns('error')
      assert_equal 2, assigns('data')['step']
    end
  end
end








