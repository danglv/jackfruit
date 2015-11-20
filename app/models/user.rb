class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :omniauthable,
         # :confirmable,
         :omniauth_providers => [:google_oauth2, :facebook]
  TEMP_EMAIL_PREFIX = 'tudemy@me'
  TEMP_EMAIL_REGEX = /\A[^@]+@[^@]+\z/

  field :wishlist, type: Array, default: []

  ## Database authenticatable
  field :email, type: String, default: ""
  field :encrypted_password, type: String, default: ""

  # Authentication tokens
  field :auth_token, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Social
  field :meta_data, type: Hash, default: {}

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  # Profile
  # Basic
  field :role, type: String, default: "user"
  field :name, type: String
  field :desination,type: String, default: ""
  field :job,type: String, default: ""
  field :first_name,type: String, default: ""
  field :last_name,type: String, default: ""
  field :headline,type: String, default: ""
  field :profile_url, type: String, default: ""
  field :avatar, type: String, default: ""

  # Biography
  field :biography,type: String, default: ""
  # Language
  field :lang,type: String, default: "vi"

  # Links
  field :links, type: Hash, default: {
    website: "",
    google: "",
    twitter: "",
    facebook: "",
    linkedin: "",
    youtube: ""
  }

  # Money
  field :money, type: Float, default: 0.0

# Tỉ lệ chia tiền cho thầy: thầy bán
  field :seller_teacher_rev_share, type: Float, default: 0.0
  # Tỉ lệ chia tiền cho thầy: TOPICA bán
  field :seller_topica_rev_share, type: Float, default: 0.0

  # Thông tin doanh thu và tài khoản còn lại của thầy
  field :total_revenue, type: Integer, default: 0
  field :balance, type: Integer, default: 0

  # Validate
  validates_inclusion_of :lang, :in => Constants.UserLangValues
  validates_numericality_of :money, greater_than_or_equal: 0
  validates_uniqueness_of :email

  embeds_one :instructor_profile, class_name: "User::InstructorProfile"
  # embeds_one :profile, class_name: "User::Profile"
  embeds_many :courses, class_name: "User::Course"
  accepts_nested_attributes_for :courses
  accepts_nested_attributes_for :instructor_profile

  has_many :certificates, class_name: "Certificate"

  has_and_belongs_to_many :labels, class_name: "Label"

  index({created_at: 1})

  before_save :must_name
  before_destroy :destroy_all_related_data

  def destroy_all_related_data
    UserGetCourseLog.where(user_id: self.id).destroy_all

    Payment.where(user_id: self.id).destroy_all

    LevelLog.where(user_id: self.id).destroy_all
  end

  def self.find_for_oauth(auth, signed_in_resource = nil)
    # Get the identity and user if they exist
    identity = Identity.find_for_oauth(auth)
    # If a signed_in_resource is provided it always overrides the existing user
    # to prevent the identity being locked with accidentally created accounts.
    # Note that this may leave zombie accounts (with no associated identity) which
    # can be cleaned up at a later date.
    user = signed_in_resource ? signed_in_resource : identity.user

    # Edit user email facebook(Đăng LV: fix changelog fb api v2.4)
    if user
      user.email = auth.info.email
      user.meta_data = auth.extra.raw_info
      user.save
    end

    # Create the user if needed
    if user.nil?

      # Get the existing user by email if the provider gives us a verified email.
      # If no verified email was provided we assign a temporary email and ask the
      # user to verify it on the next step via UsersController.finish_signup
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email
      avatar = ""
      avatar = "https://graph.facebook.com/#{auth.uid}/picture" if auth.provider == "facebook"
      avatar = auth.extra.raw_info.picture if auth.provider == "google_oauth2"
      # Create the user if it's a new registration
      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          avatar: avatar,
          #username: auth.info.nickname || auth.uid,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: Devise.friendly_token[0,20]
        )
        user.meta_data = auth.extra.raw_info
        user.save
      end
    end

    # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    # Uncomment the section below if you want users to be created if they don't exist
    unless user
      user = User.create(name: data["name"],
         email: data["email"],
         password: Devise.friendly_token[0,20]
      )
    end
    user
  end

  def role_enum
    %w[admin reviewer user test]
  end

  def lang_enum
    Constants.CourseLangValues
  end

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  def must_name
    self.name = self.email.split('@').first if self.name.blank?
  end
end
