class Label
  include Mongoid::Document

  field :status, type: Integer, default: 0
  field :name, type: String, default: ""

  belongs_to :course, class_name: "Course"
end