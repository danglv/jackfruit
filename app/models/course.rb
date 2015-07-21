class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ""
  field :lang, type: String, default: "vi"
  field :price, type: Integer, default: 0

  field :sub_title, type: String, default: ""
  field :description, type: String, default: ""
  field :requirement, type: String, default: ""
  field :benefit, type: String, default: ""
  field :audience, type: String, default: ""
  
  field :enabled, type: Boolean, default: false
  field :level, type: String, default: "all"
  
  field :average_rating, type: Float, default: 0
  field :num_rate, type: Integer, default: 0
  field :students, type: Integer, default: 0

  field :image, type: String, default: "avatar.png"
  field :intro_link, type: String, default: ""
  field :intro_image, type: String, default: ""

  embeds_many :curriculums, class_name: "Course::Curriculum"
  embeds_many :discussions, class_name: "Course::Discussion"
  embeds_many :reviews, class_name: "Course::Review"

  accepts_nested_attributes_for :curriculums, :discussions, :reviews

  belongs_to :user
  has_and_belongs_to_many :categories, class_name: "Category"
  has_and_belongs_to_many :labels, class_name: "Label"

  index({name: 1, created_at: 1})
  
  validates_presence_of :name
  validates_numericality_of :price, :num_rate, only_integer: true, greater_than_or_equal: 0
  validates_inclusion_of :lang, :in => Constants.CourseLangValues

  before_save :process_rate

  def process_rate
    rates = self.reviews.map(&:rate)
    self.num_rate = rates.count
    
    self.average_rating = if rates.count == 0 
      0
    else
      rates.sum / rates.count
    end
  end

  def num_discussion
    self.discussions.count
  end

  def num_lecture
    self.curriculums.where(type: "lecture").count
  end
end
