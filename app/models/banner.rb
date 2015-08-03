class Banner
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enabled, type: Boolean, default: false
  field :location, type: String, default: Constants::BannerLocation::HEADER
  field :url, type: String, default: ""
  field :target, type: String, default: Constants::BannerTargetTypes::SELF
  field :layout, type: String, default: "application_index"
  field :type , type: String, default: Constants::BannerTypes::IMAGE
  field :open_one_time_for_user, type: Boolean, default: false
  has_and_belongs_to_many :opened_users, class_name: "User", inverse_of: nil

  mount_uploader :banner_image, BannerImageUploader

  validates_inclusion_of :target, :in => Constants.BannerTargetTypesValues
  validates_inclusion_of :type, :in => Constants.BannerTypesValues
  validates_inclusion_of :location, :in => Constants.BannerLocationValues

	routes = Rails.application.routes.routes.map do |route|
		if (!route.defaults[:controller].blank? && !["devise/sessions", "omniauth_callbacks", "devise/passwords", "devise/registrations", "rails/info", "rails/welcome", "rails/mailers"].include?(route.defaults[:controller]))
			"#{route.defaults[:controller]}_#{route.defaults[:action]}"
		end
	end

	routes -= [nil]

	validates_inclusion_of :layout, :in => routes
end
