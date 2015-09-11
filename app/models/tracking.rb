require "net/http"
require "uri"

class Tracking
  include Mongoid::Document
  include Mongoid::Timestamps

  # Tracking thuộc loại gì Tracking Payment, Login 
  field :type, type: String

  field :content, type: Hash

  field :ip, type: String

  field :platform, type: Hash

  field :device, type: Hash

  field :version, type: String
  # user_id hoặc unique string cho anonymous user
  field :str_identity, type: String
  # id cua 1 course hoac string dai dien cho App
  field :object, type: String

  validates_uniqueness_of :str_identity

  def self.generate_unique_str
    SecureRandom.urlsafe_base64
  end

  def self.create_tracking data
    t = Tracking.create data
    uri = URI.parse("http://email.pedia.vn/email_services/send_email")

    Net::HTTP.post_form(uri, {
      :email => "quangnk@topica.edu.vn",
      :str_html => "Lỗi tracking id: #{t.id}",
      :sender => "topicamemo2@memo.net.vn",
      :subj => "Lỗi hệ thống Pedia."
    })

    Net::HTTP.post_form(uri, {
      :email => "hieubt@topica.edu.vn",
      :str_html => "Lỗi tracking id: #{t.id}",
      :sender => "topicamemo2@memo.net.vn",
      :subj => "Lỗi hệ thống Pedia."
    })
  end
end