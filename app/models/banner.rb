class Banner
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enabled, type: Boolean, default: false
  field :location, type: String, default: ""
  field :url, type: String, default: ""
  
  mount_uploader :banner_image, BannerImageUploader
end
