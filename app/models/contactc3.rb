class Contactc3
  include Mongoid::Document
  include Mongoid::Timestamps

  # Contact status
  module Status
    EXPIRED   = 'expired'   # Old contact, dont'care
    IMPORTED  = 'imported'  # Contact is imported, going to be exported
    REQUESTED = 'requested' # Someone requested but haven't confirmed yet
    EXPORTED  = 'exported'  # Contact is exported

    def self.values
      [EXPIRED, EXPORTED, IMPORTED, REQUESTED]
    end
  end

  field :name, type: String, default: ''
  field :mobile, type: String, default: ''
  field :email, type: String, default: ''
  field :course_id, type: String, default: ''
  field :course_name, type: String, default: ''
  field :msg, type: String, default: ''
  field :type, type: String, default: ''
  field :status, type: String, default: Status::IMPORTED

  validates_inclusion_of :status, :in => Status.values

  def self.insert_contactc3 data
    Contactc3.create(data)
  end
end
