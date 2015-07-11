class User::Setting
  include Mongoid::Document

  
  embedded_in :user, class_name: "User"
end
