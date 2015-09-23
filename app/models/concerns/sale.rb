#
module Sale
  class Services
    def get_price(course)
      data = { 'discount' => 0, 'discount_ratio' => 0 }

      sale_campaigns = Sale::Campaign.in_progress
      sale_campaigns.each { |campaign|
        package = campaign.packages.select { |p|
          (p.courses.count == 1) && (p.courses.first.id == course.id)
        }.first

        unless package.blank?
          data['discount'] = package.price || 0
          data['discount_ratio'] = (package.price.to_f / course.price.to_f * 100).ceil.to_i || 0
        end
      }

      data
    end
  end

  class Coupon
    def self.find_all
     response = RestClient.get('http://code.pedia.vn/coupon/list_coupon?course_id=all')
     data = JSON.parse(response)
     data['coupons'].select { |coupon| coupon['expired_date'].to_time > Time.now() }
    end

    def self.find_one(coupon_code, course)
      response = RestClient.get("http://code.pedia.vn/coupon?coupon=#{coupon_code}")
      data = JSON.parse(response)
      data['coupons'].select { |coupon| coupon['expired_date'].to_time > Time.now() && course.id.to_s == coupon['course_id'].to_s }
    end
  end
end