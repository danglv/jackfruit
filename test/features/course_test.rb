require 'test_helper'

feature 'Authentication' do
  before do
    @instructor = User.create(
      email: 'nguyendanhtu@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )

    instructor_profiles = User::InstructorProfile.create([
      {
        academic_rank: 'Doctor',
        user: @instructor
      }
    ])

    @student = User.create(
      email: 'student@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )

    @courses = Course.create([
      {
        name: 'Test Course 1',
        price: 199000,
        alias_name: 'test-course-1',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      }
    ])
  end

  after do
    User.delete_all
    Course.delete_all
    Payment.delete_all
  end

  scenario 'User should be able to visit activating page and check activation code' do
    activate_code = 'AN_INVALID_ACTIVATION_CODE'
    
    stub_request(:get, "http://code.pedia.vn/cod/detail?cod=#{activate_code}")
      .to_return(status: 422,
        body: '{"message": "Mã cod không tồn tại"}',
        headers: {}
      )
    
    visit '/courses/activate'

    page.must_have_content('Kích hoạt mã khóa học')

    within('.active-course-form') do
      fill_in('activation_code', with: "#{activate_code}")
      find('.btn-activate').click
    end

    page.must_have_content('Mã kích hoạt không hợp lệ, vui lòng thử lại')
  end
end