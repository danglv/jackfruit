class Course::Discussion
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :status, type: Integer, default: Constants::DiscussionStatus::ENABLE
  
  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :curriculum_id, type: String, default: ""

  embeds_many :child_discussions, class_name: "Course::ChildDiscussion"
  embedded_in :course
  belongs_to :user

  accepts_nested_attributes_for :child_discussions

  validate :validate_user
  validate :validate_description

  def validate_user
    user = User.where(:id => user_id).first
    errors.add(:user_id, "User bỏ trống hoặc không tồn tại.") if user.blank?
  end

  def validate_description
    errors.add(:user_id, "Thảo luận không có nội dung.") if description.blank?
  end
end