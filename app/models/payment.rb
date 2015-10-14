class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, class_name: "User"
  belongs_to :course, class_name: "Course"

  # user info
  field :name, type: String, default: ""
  field :email, type: String, default: ""
  field :mobile, type: String, default: ""
  field :address, type: String, default: ""
  field :city, type: String, default: ""
  field :district, type: String, default: ""

  field :method, type: String, default: Constants.PaymentMethodValues.first
  field :status, type: String, default: Constants::PaymentStatus::PENDING

  # COD code
  field :cod_code, type: String

  # lưu giá bán
  field :money, type: Integer, default: 0
  # Lưu người bán
  field :seller, type: String, default: Constants::Seller::TOPICA
  # Lưu coupon
  field :coupons, type: Array, default: []

  validates :course_id, :user_id, presence: true
  validates_inclusion_of :method, :in => Constants.PaymentMethodValues
  # validates_uniqueness_of :user_id, :scope => :course_id, :if => Proc.new{|obj| obj.status == Constants::PaymentStatus::SUCCESS}
  # validates_uniqueness_of :user_id, :scope => :course_id, :if => Proc.new{|obj| 
  #   ((obj.status == Constants::PaymentStatus::PENDING || obj.status == Constants::PaymentStatus::PROCESS) && obj.method == Constants::PaymentMethod::COD)
  # }
  validate :check_method_cod
  validate :unique_user_course

  before_save :update_status
  before_destroy :check_owned_course
  after_save :payment_to_success


  def unique_user_course
    payment = Payment.where(
      :user_id => self.user_id,
      :course_id => self.course_id,
      :status => Constants::PaymentStatus::SUCCESS
    ).first

    errors.add(:user_id, "khoa hoc da duoc mua thanh cong") unless payment.blank?
  end

  def check_method_cod
    cod_payment = Payment.where(
      :user_id => self.user_id,
      :course_id => self.course_id,
      :method => "cod",
      :cod_code.nin => [nil, ""],
      :id.ne => self.id
    ).or(
      {:status => "pending"},
      {:status => "process"}
    ).first

    errors.add(:user_id, "cod for this user has been booked, can't cancel") unless cod_payment.blank?
  end

  def status_enum
    Constants.PaymentStatusValues
  end

  def method_enum
    Constants.PaymentMethodValues
  end

  def update_status
    current_user = self.user

    if current_user != nil
      if self.status == Constants::PaymentStatus::CANCEL
        current_user.courses.where(course_id: self.course_id).destroy
      else
        owned_course = current_user.courses.where(course_id: self.course_id).first
        owned_course.set(payment_status: self.status) unless owned_course.blank?
      end
    end

  end

  def check_owned_course
    current_user = self.user
    if current_user != nil
      current_user.courses.where(course_id: self.course_id).destroy
    end
  end

  # Generated array of sorted predefined length trunks from a MD5 hash
  # If greedy mode is on, then more trunks will be generated
  def unique_hashes(options = {})
    length = options[:length] || COD_CODE_LENGTH   # 5
    greedy = options[:greedy] || false

    unique_string = self.id.to_s + "_#{self.created_at.to_i}"
    hash = Digest::MD5.hexdigest(unique_string)

    return hash.scan(/.{#{length}}/).uniq.sort unless greedy

    (0..(hash.length-length)).map {|start|
      hash[start..start+length-1]
    }.uniq.sort
  end

  def generate_cod_code
    return self.cod_code if self.cod_code
    
    unique_hashes = self.unique_hashes
    unique_hashes -= Payment.where(
      :code_code.in => unique_hashes
    ).distinct(:cod_code)

    # Only greedy if normal unique hashes are all used
    if unique_hashes.blank?
      unique_hashes = self.unique_hashes(greedy: true)
      unique_hashes -= Payment.where(
        :cod_code.in => unique_hashes
      ).distinct(:cod_code)
    end

    cod_code = unique_hashes.first
    self.set(cod_code: cod_code)

    cod_code
  end

  def payment_to_success
    if self.status == Constants::PaymentStatus::SUCCESS
      # Tracking L8s
      Spymaster.params.cat('L8s').beh('submit').tar(self.course.id).user(self.user.id).ext({:payment_id => self.id,
          :payment_method => self.method}).track(nil)
    end
  end
end