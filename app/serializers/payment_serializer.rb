class PaymentSerializer < ActiveModel::Serializer
  attributes :id

  self.root = false

  def id
    object.id.to_s
  end

  def cod_hash
    {
      id: self.id,
      name: object.name,
      course: object.course.name,
      coupons: object.coupons.join(", "),
      mobile: object.mobile,
      email: object.email,
      address: object.address,
      method: object.method,
      created_at: object.created_at
    }
  end
end
