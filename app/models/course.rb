class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ""
  field :description, type: String, default: ""
  field :lang, type: String, default: ""
  field :price, type: Integer, default: 0
  
  field :enabled, type: Boolean, default: false
  
  field :likes, type: Integer, default: 0
  field :average_rating, type: Float, default: 0
  field :num_rate, type: Integer, default: 0

  embeds_many :curriculums, class_name: "Course::Curriculum"
  embeds_many :discussions, class_name: "Course::Discussion"
  embeds_many :reviews, class_name: "Course::Review"

  accepts_nested_attributes_for :curriculums, :discussions, :reviews

  belongs_to :user
  has_and_belongs_to_many :categories, class_name: "Category"
  has_and_belongs_to_many :labels, class_name: "Label"

  index({name: 1, created_at: 1})
  
  validates_presence_of :name
  validates_numericality_of :price, :likes, :num_rate, only_integer: true, greater_than_or_equal: 0
  validates_inclusion_of :lang, :in => Constants.CourseLangValues
end
