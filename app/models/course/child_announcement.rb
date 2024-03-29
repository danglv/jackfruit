class Course::ChildAnnouncement
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  field :description, type: String, default: ""

  belongs_to :user
  embedded_in :parent_announcement, class_name: "Course::Announcement"
end