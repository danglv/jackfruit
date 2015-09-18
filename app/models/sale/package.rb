#
module Sale
  ##
  class Package
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String, default: ''
    field :price, type: Float, default: 0.0

    embeds_many :courses, class_name: 'Sale::Course'

    belongs_to :campaign, class_name: 'Sale::Campaign'
  end
end
