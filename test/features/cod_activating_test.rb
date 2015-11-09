require 'test_helper'

feature 'Authentication' do
  before do
    stub_request(:get, /tracking.pedia.vn/)
      .to_return(:status => 200, :body => '', :headers => {})
    stub_request(:post, /email.pedia.vn/)
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
      image: '', 
      intro_link: '', 
      intro_image: '', 
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

  after do
    Payment.delete_all
    Course.delete_all
    User.delete_all
  end

  scenario 'user activates course by cod then goes to learning page' do
    visit '/cod/activate'

    within('.activate-cod-form') do
      fill_in('cod_code', with: @payment.cod_code)
      find('.btn-activate').click
    end

    page.must_have_content('kích hoạt thành công')

    find('.btn-learning').click

    page.must_have_content('Chúc mừng bạn đã thanh toán thành công')
  end
end
