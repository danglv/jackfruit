class User::Course
  include Mongoid::Document

  field :status, type: String, default: ""
  field :type, type: String, default: ""

  embedded_in :user
  belongs_to :course, class_name: "Course"
  embeds_many :lectures, class_name: "User::Lecture"
  accepts_nested_attributes_for :lectures

  validates_inclusion_of :type, :in => Constants.OwnedCourseTypesValues
end