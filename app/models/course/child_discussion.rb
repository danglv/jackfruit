class Course::ChildDiscussion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: Constants::DiscussionStatus::ENABLE
  field :description, type: String, default: ""

  belongs_to :user
  embedded_in :parent_discussion, class_name: "Course::Discussion"
end