require 'test_helper'

# Unit tests for module Sale
module Sale
  describe 'Campaign' do
    let(:sale_campaign) { Sale::Campaign.new }
    let(:campaign) { Sale::Campaign.where(title: 'Test Sale Campaign 1').first }

    it 'must be valid' do
      value(sale_campaign).must_be :valid?
    end

    it 'must have in_progress scope' do
      value(Sale::Campaign.in_progress.all.to_a[0].title).must_equal campaign.title
    end

    it 'must have at least a course package' do
      packages = campaign.packages
      value(packages.count).must_be :>=, 1
    end
  end

  describe 'Package' do
    let(:sale_package) { Sale::Package.new }

    it 'must be valid' do
      value(sale_package).must_be :valid?
    end
  end

  describe 'Services' do
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
          price: 599000,
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
        }
      ])
    end            

    after :each do
      @users.each { |x| x.destroy }
      @courses.each { |x| x.destroy }
      @campaign.destroy
      @packages.each { |x| x.destroy }
    end

    it 'should round down price in k-base' do
      course = @courses[1]
      stub_request(:get, 'http://code.pedia.vn/coupon?coupon=A_VALID_COUPON')
        .to_return(
          :status => 200,
          :body => [
            '{"_id": "56027caa8e62a475a4000023"',
            '"coupon": "A_VALID_COUPON"',
            '"created_at": ' + Time.now().to_json,
            '"expired_date": ' + (Time.now() + 2.days).to_json,
            '"used": 0',
            '"enabled": true',
            '"max_used": 1',
            '"course_id":"' + course.id.to_s + '"',
            '"discount": 80',
            '"return_value": "50"',
            '"issued_by": "hailn"}'].join(','),
          :headers => {})

      course.price = 599000
      sale_info = Sale::Services.get_price({ course: course, coupon_code: 'A_VALID_COUPON' })

      value(sale_info[:final_price]).must_equal(119000)
    end

    it 'should return a valid package if combo_code exists and package is open' do
      combo_package = Sale::Services.get_combo('A_COMBO_CODE')

      assert_equal(79000, combo_package.price)
      assert_equal(3, combo_package.courses.size)
    end

    it 'should return nil if combo_code doesnt exists' do
      combo_package = Sale::Services.get_combo('INVALID_COMBO_CODE')

      assert_nil(combo_package)
    end
  end
end
