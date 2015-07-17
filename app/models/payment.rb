class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, class_name: "User"

  field :name, type: String, default: ""
  field :email, type: String, default: ""
  field :mobile, type: String, default: ""
  field :address, type: String, default: ""
  field :city, type: String, default: ""
  field :district, type: String, default: ""

end