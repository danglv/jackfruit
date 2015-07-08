class User::Course
  include Mongoid::Document

  field :status, type: Integer, default: 0

  embedded_in :user
  belongs_to :course, class_name: "Course"
  embeds_many :lectures, class_name: "User::Lecture"
  accepts_nested_attributes_for :lectures
end