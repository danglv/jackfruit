class User::Course
  include Mongoid::Document

  embedded_in :user
  belongs_to :course, class_name: "Course"

  field :status, type: Integer, default: 0
end