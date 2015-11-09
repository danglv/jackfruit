require 'test_helper'

feature 'Sale' do
  before do
    @instructor = User.create(
      email: 'instructor1@pedia.vn',
      password: '12345678',
      password_confirmation: '12345678'
    )

    instructor_profiles = User::InstructorProfile.create([
      {
        academic_rank: 'Doctor',
        user: @instructor
      }
    ])
    
    @courses = Course.create([
      {
        name: 'Test Course 1',
        price: 199000,
        alias_name: 'test-course-1',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      },
      {
        name: 'Test Course 2',
        price: 199000,
        alias_name: 'test-course-2',
        version: Constants::CourseVersions::PUBLIC,
        enabled: true,
        user: @instructor
      }
    ])

    @sale_campaigns = Sale::Campaign.create([
      {
        title: 'Test Sale Campaign 1',
        start_date: Time.now,
        end_date: Time.now + 2.days
      }
    ])

    @sale_packages = Sale::Package.create([
      {
        title: 'Test Sale Package 1',
        price: 98000,
        campaign: @sale_campaigns[0],
        courses: [@courses[0]],
        participant_count: 2,
        max_participant_count: 10,
        start_date: Time.now,
        end_date: Time.now + 2.days
      }
    ])
  end

  after do
    User.delete_all
    Course.delete_all
  end

  scenario 'User visits a course detail which is on sale' do
    visit '/courses/test-course-1/detail'

    # if Capybara.current_session.driver.browser.respond_to? 'manage'
    #   Capybara.current_session.driver.browser.manage.window.resize_to(320, 480)
    # end

    page.must_have_content('Test Course 1')
    page.must_have_content('199,000')
    page.must_have_content('98,000')
    page.must_have_content('50%')
    page.wont_have_content('NaN')
  end

  scenario 'User visits a course detail which is not on sale' do
    visit '/courses/test-course-2/detail'

    page.must_have_content('Test Course 2')
    page.must_have_content('199,000')
    page.wont_have_content('98,000')
    page.wont_have_content('50%')
  end

  scenario 'User visits a course with a coupon' do
    course = @courses[1]

    stub_request(:get, "http://code.pedia.vn/coupon?coupon=A_VALID_COUPON")
      .with(:headers => {
        'Accept'=>'*/*; q=0.5, application/xml',
        'Accept-Encoding'=>'gzip, deflate',
        'User-Agent'=>'Ruby'
        }
      )
      .to_return(:status => 200,
                 :body => [
                    '{"_id": "56027caa8e62a475a4000023"',
                    '"coupon": "A_VALID_COUPON"',
                    '"created_at": ' + Time.now().to_json,
                    '"expired_date": ' + (Time.now() + 2.days).to_json,
                    '"used": 0',
                    '"enabled": true',
                    '"course_id": "' + course.id + '"',
                    '"max_used": 1',
                    '"discount": 80',
                    '"return_value": "50"',
                    '"issued_by": "hailn"}'].join(','),
                  :headers => {}
                )

    visit '/courses/test-course-2/detail?coupon_code=A_VALID_COUPON'

    page.must_have_content('Test Course 2')
    page.must_have_content('39,000')
    page.must_have_content('80%')
  end
end