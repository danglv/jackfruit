class UserSerializer < ActiveModel::Serializer
  attributes :id

  self.root = false

  def id
    object.id.to_s
  end

  def suggestion_search_hash
    {
      id: self.id,
      name: object.name
    }
  end

  def profile_detail_hash
    {
      id: self.id,
      name: object.name,
      courses: object.courses.where(type: 'learning').map { |course|
        User::CourseSerializer.new(course).detail_hash
      }
    }
  end
end
