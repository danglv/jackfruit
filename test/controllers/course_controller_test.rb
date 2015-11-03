require 'test_helper'

describe 'CoursesController' do
  before :each do 
    @coupon_code = 'KHANHDN'
    @res_coupon = '{"_id":"56363fe48e62a4142f0000a3","coupon":"KHANHDN","created_at":"2015-11-01T16:37:56.232Z","expired_date":"2015-12-30T17:00:00.000Z","course_id":"560b4e96eb5d8904c1000002","used":0,"enabled":true,"max_used":1,"discount":100.0,"return_value":"100","issued_by":"560b4e95eb5d8904c1000000"}'
    @users = User.create([
      {
        _id: '56122655df52b90f8a000012',
        email: 'thanh_it@hotmail.com',
        password: '12345678',
        password_confirmation: '12345678'
      }
    ])
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
        user_id: '56122655df52b90f8a000012', 
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
      }
    ])
  end

  after :each do 
    User.delete_all
    Course.delete_all
  end

  describe 'POST #get_money' do 
    it 'should render 422 and message when course_id is blank' do 
      get :get_money
      res = JSON.parse(response.body)
      
      assert_response :unprocessable_entity
      assert_equal 'course_id không chính xác', res['message']
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
      assert_equal 'Chưa truyền dữ liệu', res['message']
    end

    it 'should render success and price' do 
      stub_request(:get, "http://code.pedia.vn/coupon?coupon=#{@coupon_code}").
        to_return(:status => 200, :body => @res_coupon) 
      get :get_money, {
        course_id: @courses[0]['id'],
        coupon_code: @coupon_code
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_match 'price', res.to_s
    end
  end

  describe 'POST #upload_course' do
    
    it 'should render 422 and message when request without user_id' do
      post :upload_course

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Chưa truyền dữ liệu', res['message']
    end

    it 'should render 422 and message when have no curriculums' do
      course = @courses[0].as_json
      course['curriculums'] = []

      post :upload_course, {
        user_id: @users[0]['id'].to_s,
        course_id: @courses[0]['id'].to_s,
        course: course
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Không được bỏ trống curriculum', res['message']
    end

    it 'should render 422 and message when course can"t save' do 
      course = @courses[0].as_json
      course['price'] = 'test'
      post :upload_course, {
        user_id: @users[0]['id'].to_s,
        course_id: @courses[0]['id'].to_s,
        course: course
      }

      res = JSON.parse(response.body)
      
      assert_response :unprocessable_entity
      assert_equal 'Lỗi không lưu được data', res['message']
    end

    it 'should render 200 and json when course can save' do 
      
      post :upload_course, {
        user_id: @users[0]['id'].to_s,
        course_id: @courses[0]['id'].to_s,
        course: @courses[0].as_json
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_not_equal 'Lỗi không lưu được data', res.to_s
    end

    it 'should render 422 and message when received exception' do     
      post :upload_course, {
        user_id: @users[0]['id'].to_s,
        course_id: @courses[0]['id'].to_s,
        course: @courses[0].to_json
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
    end
  end

  describe 'POST #approve' do 
    it 'should render 422 and message when can not found course' do
      post :approve, {
        id: 'id'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Course id Không chính xác!", res['message']
    end

    it 'should render 200 and message when course is approved' do
      post :approve, {
        id: @courses[0].id
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_equal "Success!", res['message']
    end
  end

  describe "POST #unpublish" do 
    it 'should render 422 and message when can not found course' do
      post :unpublish, {
        id: 'id'
      }

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal "Course id Không chính xác!", res['message']
    end

    it 'should render 200 and message when course is unpublish' do
      post :unpublish, {
        id: @courses[0].id
      }

      res = JSON.parse(response.body)

      assert :success
      assert_equal "Success!", res['message']
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

  describe 'POST #check_alias_name' do 
    it 'should return 422 and message when alias is blank' do 
      post :check_alias_name

      res = JSON.parse(response.body)

      assert_response :unprocessable_entity
      assert_equal 'Chưa truyền alias_name', res['message']
    end

    it 'should return success and num_courses when not found alias name' do
      post :check_alias_name, {
        alias_name: 'alias_name',
        course_id: 'course_id'
      }

      res = JSON.parse(response.body)

      assert_response :success
      assert_match 'num_courses', res.to_s
    end
  end
end