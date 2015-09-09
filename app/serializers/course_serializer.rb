class CourseSerializer < ActiveModel::Serializer
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
end
