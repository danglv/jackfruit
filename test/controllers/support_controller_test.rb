require 'test_helper'

describe 'SupportController' do
  before :each do
    @user = User.create(
      email: 'test_account_1@gmail.com',
      password: '12345678',
      password_confirmation: '12345678',
      role: 'user'
    )

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

    @course = Course.create(
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
    )
  end
  after :each do
    User.delete_all
    Course.delete_all
    Report.delete_all
  end

  describe 'POST #send_report' do
    it 'return error when param content missing' do 
      sign_in @user

      post :send_report, {
        course_id: @course.id
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Nội dung không được để trống', res['error']
    end

    it 'return error when param course_id missing' do 
      sign_in @user

      post :send_report, {
        content: 'This is content'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Course_id không được để trống', res['error']
    end

    it 'return error when param course is not exist' do 
      sign_in @user

      post :send_report, {
        content: 'This is content',
        course_id: 'INVALID_COURSE_ID'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Course không tồn tại', res['error']
    end

    it 'return success when create report success' do 
      sign_in @user

      post :send_report, {
        content: 'This is content',
        course_id: @course.id.to_s
      }

      res = JSON.parse(response.body)
      report = assigns['report']

      assert_response :success
      assert_equal 'Report thành công', res['message']
      assert_equal report.user_id, @user.id
      assert_equal report.course_id, @course.id
      assert_equal 'This is content', report.content
    end
  end
end








