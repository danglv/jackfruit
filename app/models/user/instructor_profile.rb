class User::InstructorProfile
  include Mongoid::Document

  field :academic_rank, type: String, default: ""
  field :major, type: String, default: ""
  field :function, type: String, default: ""
  field :work_unit, type: String, default: ""
  field :description, type: Array, default: []

  embedded_in :user
  
end