class Admin
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

  field :role, type: String, default: "agency"
  
  ALL_ROLES = {
    "sysop" => %w[sysop],
    "technical" => %w[incubator moderator admin],
    "marketing" => %w[agency manager],
  }

  field :role, type: String, default: "incubator"
  validates_inclusion_of :role, :in => ALL_ROLES.values.flatten
  validates_presence_of :role

  ALL_ROLES.each {|department, roles|
    define_method("#{department}?") {
      if self.role == "sysop"
        true
      else
        roles.include?(self.role)
      end
    }

    roles.each_with_index {|role, index|
      define_method("#{role}?") {
        if self.role == "sysop"
          true
        else
          roles[index..-1].include?(self.role)
        end
      }

      define_method("only_#{role}?") { self.role == role }
    }
  }

  def self.seeds_admins
    ALL_ROLES.each do |department, roles|
      roles.each do |role|
        Admin.find_or_create_by(
          email: "#{role}.#{department}@topica.edu.vn",
          password: "topica.tudemy",
          password_confirmation: "topica.tudemy",
          role: role
        )
      end
    end
  end

  # For rails_admin enum
  def role_enum
    ALL_ROLES.values.flatten
  end

  def self.current
    Thread.current[:admin]
  end      

  def self.current=(admin)
    Thread.current[:admin] = admin
  end
end
