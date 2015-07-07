class User::Course
  include Mongoid::Document

  embedded_in :user
  belongs_to :course, inverse_of: nil

  field :status, type: Integer, default: 0
end