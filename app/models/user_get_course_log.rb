class UserGetCourseLog
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, inverse_of: nil
  belongs_to :course, class_name: "Course", inverse_of: nil

  scope :today, -> {where(created_at: Time.now.beginning_of_day..Time.now.end_of_day)}

  validates_presence_of :user_id, :course_id

  index({user_id: 1, created_at: 1})
end