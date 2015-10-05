class Course
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  field :name, type: String, default: ""
  field :lang, type: String, default: "vi"
  field :price, type: Integer, default: 0
  field :old_price, type: Integer, default: 0

  field :alias_name, type: String, default: ""
  field :sub_title, type: String, default: ""
  field :description, type: Array, default: []
  field :requirement, type: Array, default: []
  field :benefit, type: Array, default: []
  field :audience, type: Array, default: []
  
  field :enabled_logo, type: Boolean, default: true
  field :enabled, type: Boolean, default: false
  field :level, type: String, default: "all"
  
  field :rating, type: Float, default: 0
  field :num_rate, type: Integer, default: 0
  field :students, type: Integer, default: 0

  field :image, type: String, default: "course-image.png"
  field :intro_link, type: String, default: ""
  field :intro_image, type: String, default: "course-image-intro.png"
  # role for course
  field :version, type: String, default: "test"

  # Field for searching
  field :searchable_content, type: String

  # fake_field
  field :fake_average_rating, type: Float, default: 4
  field :fake_students, type: Integer, default: 0
  field :fake_num_rate, type: Integer, default: 0
  field :fake_enabled, type: Boolean, default: true

  embeds_many :curriculums, class_name: "Course::Curriculum"
  embeds_many :discussions, class_name: "Course::Discussion"
  embeds_many :reviews, class_name: "Course::Review"
  embeds_many :announcements, class_name: "Course::Announcement"

  accepts_nested_attributes_for :curriculums, :discussions, :reviews, :announcements

  belongs_to :user
  has_and_belongs_to_many :categories, class_name: "Category"
  has_and_belongs_to_many :labels, class_name: "Label"

  index({ name: 1, created_at: 1 })

  validates_presence_of :name
  validates_numericality_of :price, :old_price, :num_rate, only_integer: true, greater_than_or_equal: 0
  validates_inclusion_of :lang, :in => Constants.CourseLangValues
  validates_inclusion_of :version, :in => Constants.CourseVersionsValues

  before_save :process_rate, :update_search_content

  def update_search_content
    name = self.name
    alias_name = self.alias_name
    desc = self.description.join(".")
    user_name = self.user.name    
    teacher_profile_obj = self.user.instructor_profile
    teacher_profile_str = ""
    
    if teacher_profile_obj
      teacher_profile_str += teacher_profile_obj.academic_rank +
        teacher_profile_obj.major + teacher_profile_obj.function +
        teacher_profile_obj.work_unit + teacher_profile_obj.description.join(".")
    end

    searchable_content = name + " " + alias_name +  " " + desc +  " " + user_name +  " " + teacher_profile_str
    searchable_content = Utils.nomalize_string(searchable_content)

    self.searchable_content = searchable_content.downcase.gsub(/[^a-zA-Z 0-9]/, " ")
  end

  def process_rate
    rates = self.reviews.map(&:rate)
    self.num_rate = rates.count
    
    self.rating = if rates.count == 0 
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

  def lang_enum
    Constants.CourseLangValues
  end

  def level_enum
    Constants.CourseLevelValues
  end

  def version_enum
    Constants.CourseVersionsValues
  end

  def average_rating
    if self.fake_enabled == true
      self.fake_average_rating
    else
      self.read_attribute(:rating)
    end
  end

  def students
    if self.fake_enabled == true
      self.fake_students
    else
      self.read_attribute(:students)
    end
  end

  def num_rate
    if self.fake_enabled == true
      self.fake_num_rate
    else
      self.read_attribute(:num_rate)
    end
  end

  def free?
    self.price == 0
  end
end
