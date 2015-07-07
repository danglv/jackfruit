class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :child_categories, class_name: "Category"

  belongs_to :parent_category, class_name: "Category"

  field :name, type: String, default: ""
  field :child_category_count, type: Integer, default: 0
  field :enabled, type: Boolean, default: true

  index({name: 1, created_at: 1, parent_category: 1})
  
  validates_presence_of :name
  validates_numericality_of :child_category_count, only_integer: true, greater_than_or_equal: 0

  before_save :calculate_child_categories

  def calculate_child_categories
    self.child_category_count = self.child_categories.count
  end
end
