#
module Sale
  #
  class Campaign
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String, default: ''
    field :start_date, type: Time
    field :end_date, type: Time

    embeds_many :packages, class_name: 'Sale::Package'
    accepts_nested_attributes_for :packages

    index(start_date: 1, end_date: 1)

    scope :in_progress, lambda {
      where(:start_date.lte => Time.now, :end_date.gte => Time.now)
    }
  end
end
