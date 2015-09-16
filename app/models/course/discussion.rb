class Course::Discussion
  include Mongoid::Document

  field :status, type: Integer, default: 0
  field :parent_discussion, type: String, default: ""
  
  field :title, type: String, default: ""
  field :description, type: String, default: ""

  embeds_many :child_discussions, class_name: "Course::Discussion"
  embedded_in :course
  belongs_to :user
  belongs_to :curriculum, class_name: "Course::Curriculum"
end