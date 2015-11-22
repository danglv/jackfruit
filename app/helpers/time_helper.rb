include ActionView::Helpers::DateHelper

module TimeHelper
	def self.relative_time(time)
    if time.blank?
      return 'khoảng 2 tháng trước'
    else
      I18n.locale = :vi
      distance_time = time_ago_in_words(time).to_s + ' trước'
      return distance_time
    end
	end
end

