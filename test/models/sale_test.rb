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

  describe 'Coupon' do
    let(:course) { Course.new }

    it 'must round down price in k-base' do
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
            '"discount": 80',
            '"return_value": "50"',
            '"issued_by": "hailn"}'].join(','),
          :headers => {})

      course.price = 599000
      sale_info = Sale::Services.get_price({ course: course, coupon_code: 'A_VALID_COUPON' })

      value(sale_info[:final_price]).must_equal(119000)
    end
  end
end
