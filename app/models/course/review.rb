class Course::Review
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  
  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :rate, type: Integer, default: 0

  embedded_in :course
  belongs_to :user
end