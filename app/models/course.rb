class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ""
  field :enabled, type: Boolean, default: false
  field :price, type: Integer, default: 0
  field :likes, type: Integer, default: 0
  field :rates, type: Integer, default: 0
  field :status, type: Integer, default: 0
  field :description, type: String, default: ""

  field :lang, type: String, default: ""

  embeds_many :curriculums, class_name: "Course::Curriculum"

  accepts_nested_attributes_for :curriculums

  belongs_to :user
  has_and_belongs_to_many :categories, class_name: "Category"
  has_and_belongs_to_many :labels, class_name: "Label"

  index({name: 1, created_at: 1})
  
  validates_presence_of :name
  validates_numericality_of :price, :likes, :rates, only_integer: true, greater_than_or_equal: 0
  validates_inclusion_of :lang, :in => Constants.CourseLangValues
end
