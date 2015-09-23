class Course::Disputation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  
  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :curriculum_id, type: String, default: ""

  # embeds_many :child_disputations, class_name: "Course::ChildDisputation"
  embedded_in :course
  belongs_to :user

  # accepts_nested_attributes_for :child_disputations

end