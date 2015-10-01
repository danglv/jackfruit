class Course::Alert
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, type: Integer, default: 0
  
  field :title, type: String, default: ""
  field :description, type: String, default: ""

  embeds_many :child_alert, class_name: "Course::ChildAlert"
  embedded_in :course
  belongs_to :user

  accepts_nested_attributes_for :child_alert

end