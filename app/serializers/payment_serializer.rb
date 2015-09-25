class PaymentSerializer < ActiveModel::Serializer
  attributes :id

  self.root = false

  def id
    object.id.to_s
  end

  def cod_hash
    {
      id: self.id,
      name: !object.name.blank? ? object.name : object.user.email,
      user_id: object.user_id.to_s,
      course_id: object.course_id.to_s,
      course_alias_name: object.course.alias_name,
      course_name: object.course.name,
      coupons: object.coupons.blank? ? "" : object.coupons.join(", "),
      mobile: object.mobile,
      email: object.email,
      address: object.address,
      method: object.method,
      created_at: object.created_at,
      money: object.money,
      city: object.city,
      district: object.district,
      cod_code: object.cod_code,
      status: object.status

    }
  end
end
