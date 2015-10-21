module Sale

  class Services

    # One interface for all (sale price for a course)
    # Input
    # Hash{
    # => course: required, except when combo_code is given
    # => coupon_code: optional
    # => combo_code: optional
    # => ...
    # }
    # Ouput
    # Hash{
    # => discount_price: price after applying sale package
    # => discount_ratio
    # => applied: true if there's a sale package applied on course, false otherwise
    # => error: message if any error, usually coupon code is not valid, should be checked first
    # => coupon_code: if there's a coupon code applying to this course
    # => combo_code: when get price for a combo
    # }
    def self.get_price(data)
      course = data[:course]

      # Default result
      result = {:final_price => course.price, :discount_ratio => 0, :applied => false}

      course = data[:course]
      # Check combo
      if (data[:combo_code])
        combo_code = data[:combo_code]
        combo_package = get_combo(combo_code)
        if combo_package
          result[:final_price] = combo_package.price
          result[:package_id] = combo_package.id
          result[:combo_code] = combo_package.code
          result[:participant_count] = combo_package.participant_count
          result[:max_participant_count] = combo_package.max_participant_count
          result[:end_date] = (combo_package.end_date ? combo_package.end_date : Time.now()).utc.to_f * 1000
          result[:applied] = true
        else
          result[:error] = "Mã combo #{combo_code} không hợp lệ"
        end
      # Check coupon
      elsif (!data[:coupon_code].blank?)
        coupon_code = data[:coupon_code]
        success, data = Coupon.request_by_code(coupon_code, course.id)

        if success
          result[:final_price] = ((100 - data['discount'].to_f) * course.price / 100000).floor * 1000
          result[:discount_ratio] = data['discount'].to_f.ceil
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
            result[:final_price] = package.price
            result[:discount_ratio] = (100 - (package.price.to_f / course.price.to_f * 100).ceil.to_i) || 0
            result[:package_id] = package.id
            result[:participant_count] = package.participant_count
            result[:max_participant_count] = package.max_participant_count
            result[:end_date] = (package.end_date ? package.end_date : Time.now()).utc.to_f * 1000
            result[:applied] = true
            break
          end
        }
      end

      result
    end

    # Get combo package by code
    def self.get_combo(combo_code)
      return Combo.request_package_by_code(combo_code)
    end
  end

  class Coupon
    GET_API = "http://code.pedia.vn/coupon"

    # Give course's id if want to specify coupon of the course
    def self.request_by_code(coupon_code, course_id = nil)
      RestClient.get("#{GET_API}?coupon=#{coupon_code}"){ |response, request, result, &block|
        data = JSON.parse(response)

        return [false,  "Mã coupon #{coupon_code} không hợp lệ"] unless result.code == '200' # data['message']]
        # If coupon is expired
        return [false, "Mã coupon #{coupon_code} không hợp lệ"] if data['expired_date'].to_time < Time.now()
        # if course_id is given but not match with coupon's course_id
        return [false, "Mã coupon #{coupon_code} không áp dụng cho khóa học"] if course_id && course_id.to_s != data['course_id']
        return [true, data]
      }
    end

    def self.request_for_course(course_id)
      RestClient.get("#{GET_API}/list_coupon?course_id=#{course_id}"){ |response, request, result, &block|
        data = JSON.parse(response)
        case result.code
        when "200"
          coupons = data['coupons'].select { |coupon| coupon['expired_date'].to_time > Time.now() }
          return true, coupons
        else
          return false, "Yêu cầu coupon thất bại"
        end
      }
    end
  end

  class Combo
    def self.request_courses_by_code(combo_code)
      # Find a campaign
      campaign = Sale::Campaign.in_progress.where(
        :'packages.code' => combo_code
      ).first
      if campaign
        package = campaign.packages.where(:code => combo_code).first
        return package.courses
      end
      return []
    end

    def self.request_package_by_code(combo_code)
      campaign = Sale::Campaign.in_progress.where(
        :'packages.code' => combo_code
      ).first
      if campaign
        return campaign.packages.where(:code => combo_code).first
      end
      return nil
    end
  end
end
