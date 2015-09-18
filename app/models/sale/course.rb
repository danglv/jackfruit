module Sale
  ##
  class Course
    include Mongoid::Document
    include Mongoid::Timestamps

    field :base_price, type: Float, default: 0.0

    embedded_in :sale_package, class_name: 'Sale::Package'

    belongs_to :course, class_name: 'Course'
  end
end