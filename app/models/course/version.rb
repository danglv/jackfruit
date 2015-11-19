class Course::Version
  include Mongoid::Document
  include Mongoid::Timestamps

  field :version_course, type: String, default: '1.0'
  field :name, type: String, default: ""
  field :lang, type: String, default: "vi"
  field :price, type: Integer, default: 0
  field :old_price, type: Integer, default: 0
  field :alias_name, type: String, default: ""
  field :sub_title, type: String, default: ""
  field :description_editor, type: String, default: ""
  field :level, type: String, default: "all"
  field :image, type: String, default: "course-image.png"
  field :intro_link, type: String, default: ""
  field :intro_image, type: String, default: "course-image-intro.png"
  field :version, type: String, default: Constants::CourseVersions::TEST

  field :rating, type: Float, default: 0
  field :num_rate, type: Integer, default: 0
  field :students, type: Integer, default: 0

  field :description, type: Array, default: []
  field :requirement, type: Array, default: []
  field :benefit, type: Array, default: []
  field :audience, type: Array, default: []
  field :labels_order, type: Array, default: []
  field :related, type: Array, default: [] #array of hash [id,...]
  # publish course
  field :is_publish, type: Boolean, default: false
  field :published_at, type: Date
  # submit for review
  field :is_submit, type: Boolean, default: false
  field :submited_at, type: Date

  field :enabled_logo, type: Boolean, default: true
  field :enabled, type: Boolean, default: false

    # fake_field
  field :fake_average_rating, type: Float, default: 4
  field :fake_students, type: Integer, default: 0
  field :fake_num_rate, type: Integer, default: 0
  field :fake_enabled, type: Boolean, default: true

  embeds_many :curriculums, class_name: "Course::Curriculum"
  embeds_many :discussions, class_name: "Course::Discussion"
  embeds_many :reviews, class_name: "Course::Review"
  embeds_many :announcements, class_name: "Course::Announcement"
  accepts_nested_attributes_for :curriculums

  belongs_to :course
  belongs_to :user
  belongs_to :staff
  
  has_and_belongs_to_many :categories, class_name: "Category"
  has_and_belongs_to_many :labels, class_name: "Label"
  
  validates_presence_of :name
  validates_numericality_of :price, :old_price, only_integer: true, greater_than_or_equal: 0
  validates_inclusion_of :lang, :in => Constants.CourseLangValues
  validates_inclusion_of :version, :in => Constants.CourseVersionsValues

  def average_rating
    if self.fake_enabled == true
      self.fake_average_rating
    else
      self.read_attribute(:rating)
    end
  end

  def num_discussion
    self.discussions.count
  end

  def num_lecture
    self.curriculums.where(type: "lecture").count
  end

  def lang_enum
    Constants.CourseLangValues
  end

  def level_enum
    Constants.CourseLevelValues
  end

  def version_enum
    Constants.CourseVersionsValues
  end

  def free?
    self.price == 0
  end
end