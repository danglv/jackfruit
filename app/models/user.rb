class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ""
  field :username, type: String, default: ""
  field :password, type: String, default: ""
  embeds_many :courses
  accepts_nested_attributes_for :courses

  index({created_at: 1})

  validates_presence_of :username, :name
end