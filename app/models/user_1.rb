class User1
  include Mongoid::Document
  include Mongoid::Timestamps

  # Account
  field :email, type: String, default: ""
  field :password, type: String, default: ""
  field :auth_token, type: String, default: ""

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

  validates_presence_of :email, :name
  validates_uniqueness_of :email
end