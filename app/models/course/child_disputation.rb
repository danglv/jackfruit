class Course::ChildDisputation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  field :description, type: String, default: ""

  belongs_to :user
  embedded_in :disputation, class_name: "Course::Disputation"
end