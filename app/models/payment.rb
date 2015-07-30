class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, class_name: "User"
  belongs_to :course, class_name: "Course"

  field :name, type: String, default: ""
  field :email, type: String, default: ""
  field :mobile, type: String, default: ""
  field :address, type: String, default: ""
  field :city, type: String, default: ""
  field :district, type: String, default: ""
  field :method, type: String, default: Constants.PaymentMethodValues.first

  validates_inclusion_of :method, :in => Constants.PaymentMethodValues
end