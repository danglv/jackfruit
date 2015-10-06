class Contactc3
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ''
  field :mobile, type: String, default: ''
  field :email, type: String, default: ''
  field :course_id, type: String, default: ''
  field :course_name, type: String, default: ''
  field :msg, type: String, default: ''
  field :type, type: String, default: ''

  def self.insert_contactc3 data
    Contactc3.create(data)
  end
end
