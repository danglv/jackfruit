class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

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
  field :sign_up_by_platform, type: String, default: ""
  field :desination,type: String, default: ""
  field :first_name,type: String, default: ""
  field :last_name,type: String, default: ""
  field :headline,type: String, default: ""
  field :profile_url, type: String, default: ""

  # Biography
  field :biography,type: String, default: ""
  # Language
  field :lang,type: String, default: "vi"
  # Links 
  field :links, type: Hash, default: {
    website: "http://",
    google_plus: "https://plus.google.com/",
    twitter_profile: "http://twitter.com/",
    facebook_profile: "http://www.facebook.com/",
    linkedin_profile: "http://www.linkedin.com/",
    youtube_profile: "http://www.youtube.com/"
  }
  # Avatar

  #

  # Validate
  validates_inclusion_of :lang, :in => Constants.UserLangValues

  embeds_one :profile, class_name: "User::Profile"
  embeds_many :courses, class_name: "User::Course"
  accepts_nested_attributes_for :courses

  index({created_at: 1})
end
