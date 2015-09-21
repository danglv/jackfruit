class User::Note
  include Mongoid::Document

  field :time, type: String, default: ""
  field :content, type: String, default: ""

  embedded_in :lectures

end