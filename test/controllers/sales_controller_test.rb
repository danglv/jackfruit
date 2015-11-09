require 'test_helper'
require 'json'

describe 'SalesController' do
  before :each do
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
      title: 'Test Sale Campaign',
      start_date: Time.now,
      end_date: Time.now + 2.days
    )

    @packages = Sale::Package.create([
      {
        title: 'Test Sale Package 1',
        price: 79000,
        campaign: @campaign,
        courses: @courses,
        participant_count: 2,
        max_participant_count: 10,
        start_date: Time.now,
        end_date: Time.now + 2.days,
        code: 'A_COMBO_CODE'
      },
    ])
  end            

  after :each do
    User.delete_all
    Course.delete_all
    Sale::Campaign.delete_all
  end

  it 'should get detail in json format if accept-header is json' do
    @request.headers['Accept'] = 'json'
    @request.headers['Content-Type'] = 'application/json'

    get :detail, combo_code: 'A_COMBO_CODE'

    assert_response :success

    response = JSON.parse(@response.body)

    assert_equal(79000, response['price'])
  end
     
  it 'should get error in json format if accept-header is json and no combo code found' do
    @request.headers['Accept'] = 'json'
    @request.headers['Content-Type'] = 'application/json'

    get :detail, combo_code: 'INVALID_COMBO_CODE'

    assert_response :success

    response = JSON.parse(@response.body)

    assert_equal('Mã combo INVALID_COMBO_CODE không hợp lệ', response['error'])
  end
end
               