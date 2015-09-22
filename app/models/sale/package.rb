#
module Sale
  ##
  class Package
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String, default: ''
    field :price, type: Float, default: 0.0

    embedded_in :campaign, class_name: 'Sale::Campaign'

    has_and_belongs_to_many :courses, class_name: 'Course', inverse_of: nil
  end
end
