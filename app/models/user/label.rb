class User::Label
  include Mongoid::Document

  field :level, type: String, default: Constants.UserLevelValues.first

  embedded_in :user
  validates_inclusion_of :level, :in => Constants.UserLevelValues
end