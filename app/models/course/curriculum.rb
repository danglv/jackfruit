class Course::Curriculum
  include Mongoid::Document

  field :status, type: Integer, default: 0
  
  field :type, type: String, default: ""
  field :order, type: Integer, default: 0
  field :chapter_index, type: Integer, default: 0
  field :lecture_index, type: Integer, default: 0
  field :object_index, type: Integer, default: 0

  field :title, type: String, default: ""
  field :description, type: String, default: ""

  field :asset_type, type: String, default: ""
  field :url, type: String, default: ""

  embedded_in :course

  validates_inclusion_of :type, :in => Constants.CurriculumTypesValues
  validates_inclusion_of :asset_type, :in => Constants.CurriculumAssetTypesValues
end