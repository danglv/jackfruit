#
module Sale
  ##
  class Package
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String, default: ''
    field :price, type: Float, default: 0.0
    field :code, type: String, default: ''	# A nice code to use instead of id or title
    field :start_date, type: Time
    field :end_date, type: Time
    field :participant_count, type: Integer, default: 0
    field :max_participant_count, type: Integer, default: 0

    embedded_in :campaign, class_name: 'Sale::Campaign'

    has_and_belongs_to_many :courses, class_name: 'Course', inverse_of: nil

    index(code: 1)

    validates_uniqueness_of :code
  end
end
