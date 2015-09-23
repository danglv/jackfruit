class User::NoteSerializer < ActiveModel::Serializer
  attributes :_id, :time, :content

  self.root = false
  
  def _id
    object.id.to_s
  end

end