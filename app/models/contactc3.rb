class Contactc3
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :mobile, type: String
  field :email, type: String
  field :course_id, type: String
  field :course_name, type: String
  field :msg, type: String
  field :type, type: String

  def insert_contactc3
    Contactc3.create(data)
  end
end
