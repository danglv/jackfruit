class User::Lecture
  include Mongoid::Document

  field :status, type: Integer, default: 0
  
  field :lecture_ratio, type: Integer, default: 0
  field :lecture_index, type: Integer
  # belongs_to :curriculum, class_name: "Course::Curriculum"
  embedded_in :course, class_name: "User::Course"
  embeds_many :notes, class_name: "User::Note"

end