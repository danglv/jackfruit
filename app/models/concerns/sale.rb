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
end