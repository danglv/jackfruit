module Sale

  class Services

    # One interface for all
    # Input
    # Hash{
    # => course: required
    # => coupon_code: optional
    # => ...
    #}
    # Ouput
    # Hash{
    # => discount_price: price after applying sale package
    # => discount_ratio
    # => applied: true if there's a sale package applied on course, false otherwise
    # => error: message if any error, usually coupon code is not valid, should be checked first
    # => coupon_code: if there's a coupon code applying to this course
    #}
    def self.get_price(data)
      # Default result
      result = {:discount_price => 0, :discount_ratio => 0, :applied => false}

      course = data[:course]
      # Check coupon 
      if (coupon_code = data[:coupon_code])
        success, data = Coupon.request_by_code(coupon_code)
        if success
          result[:discount_price] = data['discount'].to_f * course.price
          result[:discount_ratio] = data['discount'].to_i
          result[:coupon_code] = coupon_code
          result[:applied] = true
        else
          result[:error] = data
        end
      else
        # Looking for a sale package
        sale_campaigns = Sale::Campaign.in_progress
        sale_campaigns.each { |campaign|
          package = campaign.packages.select { |p|
            (p.courses.count == 1) && (p.courses.first.id == course.id)
          }.first

          unless package.blank?
            result[:discount_price] = package.price || 0
            result[:discount_ratio] = (package.price.to_f / course.price.to_f * 100).ceil.to_i || 0
            result[:applied] = true
            break
          end
        }
      end

      result
    end

  end

  class Services::Coupon
    GET_API = "http://code.pedia.vn/coupon"

    # Give course's id if want to specify coupon of the course
    def self.request_by_code(coupon_code, course_id = nil)
      RestClient.get("#{GET_API}?coupon=#{coupon_code}"){ |response, request, result, &block|
        data = JSON.parse(response)
        case result.code
        when "200"
          # if course_id is given but not match with coupon's course_id
          if course_id && course_id != data['course_id']
            return false, "Mã coupon #{coupon_code} không áp dụng cho khóa học"
          else
            return true, data
          end
        else
          return false, "Mã coupon #{coupon_code} không hợp lệ" # data['message']
        end
      }
    end

    def self.request_for_course(course_id)
      RestClient.get("#{GET_API}/list_coupon?course_id=#{course_id}"){ |response, request, result, &block|
        data = JSON.parse(response)
        case result.code
        when "200"
          coupons = data['coupons'].select { |coupon| coupon['expired_date'].to_time > Time.now()}
          return true, coupons
        else
          return false, "Yêu cầu coupon thất bại"
        end
      }
    end
  end

  class Services::Combo
    def self.request_courses_by_code(combo_code)
      # Find a campain
      campaign = Sale::Campaign.in_progress.where(
        :'packages.code' => combo_code
      ).first
      if campaign
        package = campaign.packages.where(:code => combo_code).first
        return package.courses
      end
      return []
    end
  end
end