class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :enabled, type: Boolean, default: true
  field :price, type: Integer, default: 0
  field :likes, type: Integer, default: 0
  field :rates, type: Integer, default: 0

  has_many :categories, class_name: "Category", inverse_of: nil

  index({name: 1, created_at: 1})
  
  validates_presence_of :name
  validates_numericality_of :price, :likes, :rates, only_integer: true, greater_than_or_equal: 0

end
