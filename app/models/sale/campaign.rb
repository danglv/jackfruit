#
module Sale
  class Campaign
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String, default: ''
    field :start_date, type: Time
    field :end_date, type: Time 
  end
end
