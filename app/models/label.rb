class Label
  include Mongoid::Document

  field :name, type: String, default: ""
  field :description, type: String, default: ""
  field :type, type: String, default: Constants.LabelTypesValues.first

  validates_inclusion_of :type, :in => Constants.LabelTypesValues

  def type_enum
  	Constants.LabelTypesValues
  end
end