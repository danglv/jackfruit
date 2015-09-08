class User::CourseSerializer < ActiveModel::Serializer
  attributes :_id

  self.root = false
  
  def _id
    object.id.to_s
  end

  def detail_hash
    {
      course_id: object.course.id,
      name: object.course.name,
      payment_status: object.payment_status
    }
  end
end