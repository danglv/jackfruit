class Feedback
  include Mongoid::Document

  field :name, type: String
  field :email, type: String
  field :contrnt, type: String
end