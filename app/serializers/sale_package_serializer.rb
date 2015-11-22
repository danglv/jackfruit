class SalePackageSerializer < ActiveModel::Serializer
  attributes :id, :title, :price, :participant_count, :max_participant_count, :code
  attributes :start_date, :end_date
  attributes :campaign, :courses

  self.root = false

  def id
    object.id.to_s
  end

  def campaign
    object.campaign.id.to_s
  end

  def courses
    object.courses.map { |c| c.id.to_s }
  end
end
