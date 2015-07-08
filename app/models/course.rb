class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :enabled, type: Boolean, default: false
  field :price, type: Integer, default: 0
  field :likes, type: Integer, default: 0
  field :rates, type: Integer, default: 0
  field :sttus, type: Integer, default: 0

  embeds_many :curriculums, class_name: "Course::Curriculum"

  accepts_nested_attributes_for :curriculums

  belongs_to :user
  has_many :categories, class_name: "Category", inverse_of: nil

  index({name: 1, created_at: 1})
  
  validates_presence_of :name
  validates_numericality_of :price, :likes, :rates, only_integer: true, greater_than_or_equal: 0

  # def lessons
  #   self.sections.map { |section| section.lessons }
  # end
end
