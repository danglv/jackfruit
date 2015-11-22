class Certificate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, type: String, default: ""
  field :no, type: String, default: ""

  belongs_to :user
  belongs_to :course
end
