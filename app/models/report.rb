class Report
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, class_name: "User"
  belongs_to :course, class_name: "Course"

  field :type, type: String, default: ""
  field :content, type: String, default: ""

end