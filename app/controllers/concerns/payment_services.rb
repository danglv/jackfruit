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

  class BaoKimPaymentCard
    BAOKIM_URL = 'https://www.baokim.vn/the-cao/restFul/send'
    MERCHANT_ID = '18578'
    API_USERNAME = 'tudemyvn'
    API_PASSWORD = 'tudemyvn46346fhdh'
    SECURE_PASS = '3aae0be2080c5744'
    # CORE_API_HTTP_USR = 'merchant_18578'
    # CORE_API_HTTP_PWD = '18578xzn5GkEoJXaQFP9r7syw8CTMS9flb3'

    def create_request_url(params)
      params['merchant_id'] = MERCHANT_ID
      params['api_username'] = API_USERNAME
      params['api_password'] = API_PASSWORD
      params['algo_mode'] = 'hmac'
      params = params.sort.to_h

      data = data = params.map(&:last).join('')
      data_sign = OpenSSL::HMAC.hexdigest('SHA1', SECURE_PASS, data)

      params['data_sign'] = data_sign    

      request = Net::HTTP.post_form(URI.parse("#{BAOKIM_URL}"), params)
      
      return request
    end

    def verify_response_url(params, payment)
      DateTime.parse(params[:transaction_id]).to_i == payment.created_at.to_i
    end
  end
end