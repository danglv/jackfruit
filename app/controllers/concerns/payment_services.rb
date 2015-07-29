require 'uri'
require 'digest'

module PaymentServices extend ActiveSupport::Concern
  class BaoKimPayment
    BAOKIM_URL = 'https://www.baokim.vn/payment/customize_payment/order'
    MERCHANT_ID = '18578'
    SECURE_PASS = '3aae0be2080c5744'

    def create_request_url(params)
      md5 = Digest::MD5.new
      redirect_url = BAOKIM_URL + '?'

      params['merchant_id'] = MERCHANT_ID
      params = params.sort.to_h
      params['checksum'] = md5.hexdigest(SECURE_PASS + params.map{|k, v| "#{v.to_s}"}.join('')).upcase

      url_params = params.map{|k, v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')
      redirect_url + url_params 
    end

    def verify_response_url(params)
      md5 = Digest::MD5.new
      checksum = params['checksum']

      params.delete('checksum')
      params = params.sort.to_h

      verify_checksum = md5.hexdigest(SECURE_PASS + params.map{|k, v| "#{v.to_s}"}.join('')).upcase

      verify_checksum == checksum
    end
  end
end