class LevelLog
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, inverse_of: nil

  field :level_before_up, type: String, default: Constants.UserLevelValues.first
  field :level_after_up, type: String, default: Constants.UserLevelValues.first
  field :platform, type: String
  
  validates_inclusion_of :level_before_up, :level_after_up, :in => Constants.UserLevelValues
  default_scope -> {asc(:created_at)}
end
