class User::Course
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :payment_status, type: String, default: ""
  field :type, type: String, default: ""
  field :expired_at, type: Time, default: nil
  field :first_learning, type: Boolean, default: true

  embedded_in :user
  belongs_to :course, class_name: "Course"
  embeds_many :lectures, class_name: "User::Lecture"
  accepts_nested_attributes_for :lectures

  validates_inclusion_of :type, :in => Constants.OwnedCourseTypesValues
  validates_inclusion_of :payment_status, :in => Constants.PaymentStatusValues

  def preview_expired?
    self.expired_at && self.expired_at < Time.now
  end

  def preview?
    self.type == Constants::OwnedCourseTypes::PREVIEW
  end

  def payment_success?
    self.payment_status == Constants::PaymentStatus::SUCCESS
  end

  def payment_pending?
    self.payment_status == Constants::PaymentStatus::PENDING
  end

end