class Label
  include Mongoid::Document

  field :status, type: Integer, default: 0
  
  field :name, type: String, default: ""
end