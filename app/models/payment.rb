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

  # COD code
  field :cod_code, type: String

  validates_presence_of :cod_code if :method == Constants::PaymentMethod::COD
  validates_uniqueness_of :course_id if :method == Constants::PaymentMethod::COD
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
end