class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, class_name: "User"
  belongs_to :course, class_name: "Course"

  field :name, type: String, default: ""
  field :email, type: String, default: ""
  field :mobile, type: String, default: ""
  field :address, type: String, default: ""
  field :city, type: String, default: ""
  field :district, type: String, default: ""
  field :method, type: String, default: Constants.PaymentMethodValues.first
  field :status, type: String, default: Constants::PaymentStatus::PENDING

  validates_inclusion_of :method, :in => Constants.PaymentMethodValues
  validates_uniqueness_of :course_id, scope: :user_id

  before_save :update_status
  before_destroy :check_owned_course

  def status_enum
    Constants.PaymentStatusValues
  end

  def method_enum
    Constants.PaymentMethodValues
  end

  def update_status
    current_user = self.user

    if self.status == Constants::PaymentStatus::CANCEL
      current_user.courses.where(course_id: self.course_id).destroy
    else
      owned_course = current_user.courses.where(course_id: self.course_id).first
      owned_course.set(payment_status: self.status) unless owned_course.blank?
    end
  end

  def check_owned_course
    current_user = self.user
    current_user.courses.where(course_id: self.course_id).destroy
  end
end