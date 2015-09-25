class User::Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :time, type: String, default: ""
  field :content, type: String, default: ""

  belongs_to :lecture, class_name: "User::Lecture"

end