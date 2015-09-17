include ActionView::Helpers::DateHelper

module TimeHelper
	def self.relative_time(time)

    I18n.locale = :vi
    distance_time = time_ago_in_words(time).to_s + ' trước'
    return distance_time
	end
end

