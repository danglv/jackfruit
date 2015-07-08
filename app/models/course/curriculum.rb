class Course::Curriculum
  include Mongoid::Document

  field :status, type: Integer, default: 0
  
  field :type, type: String, default: ""
  field :order, type: Integer, default: 0
  field :chapter_index, type: Integer, default: 0
  field :lecture_index, type: Integer, default: 0

  embedded_in :course

  validates_inclusion_of :type, :in => Constants.CurriculumTypesValues
end