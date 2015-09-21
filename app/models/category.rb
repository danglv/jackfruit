class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :child_categories, class_name: "Category"
  belongs_to :parent_category, class_name: "Category"

  field :name, type: String, default: ""
  field :child_category_count, type: Integer, default: 0
  field :enabled, type: Boolean, default: true
  field :order, type: Integer
  field :alias_name, type: String, default: ""
  field :description, type: String, default: ""
  field :background_color, type: String, default: "#338abc"

  index({name: 1, created_at: 1, parent_category: 1})
  
  validates_presence_of :name
  validates_numericality_of :child_category_count, only_integer: true, greater_than_or_equal: 0

  before_save :calculate_child_categories, :update_order
  after_save :update_cache

  @@cache_categories = nil
  
  def self.get_categories
    @@cache_categories = @@cache_categories || Category.where(:parent_category_id => nil, enabled: true).asc(:order).to_a
  end

  def calculate_child_categories
    self.child_category_count = self.child_categories.count
  end

  def update_order
    order = Category.where(:order.ne => nil).count - 1
    self.order = order  if self.order == nil
  end

  def update_cache
    @@cache_categories = Category.where(:parent_category_id => nil, enabled: true).asc(:order).to_a
  end
end
