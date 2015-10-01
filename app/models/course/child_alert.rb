class Course::ChildAlert
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  field :description, type: String, default: ""

  belongs_to :user
  embedded_in :parent_alert, class_name: "Course::Alert"
end