require 'uri'
require 'digest'
require 'net/http'
require 'net/https'
require 'net/http/digest_auth'

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
  
  module BaoKimConstant
    EMAIL_BUSINESS = 'ngoc.phungba@gmail.com'
    MERCHANT_ID = 18578
    SECURE_PASS = '3aae0be2080c5744'

    API_USER = 'ngocpb'
    API_PWD = 'Xu8rqP99hWfBQMU316e4moisK63El'
    PRIVATE_KEY_BAOKIM = ENV['BAOKIM_PRIVATE_KEY']

    BAOKIM_API_SELLER_INFO = '/payment/rest/payment_pro_api/get_seller_info'
    BAOKIM_API_PAY_BY_CARD = '/payment/rest/payment_pro_api/pay_by_card'
    BAOKIM_API_PAYMENT = '/payment/order/version11'

    BAOKIM_URL = 'https://www.baokim.vn'

    PAYMENT_METHOD_TYPE_LOCAL_CARD = "1"
    PAYMENT_METHOD_TYPE_CREDIT_CARD = "2"
    PAYMENT_METHOD_TYPE_INTERNET_BANKING = "3"
    PAYMENT_METHOD_TYPE_ATM_TRANSFER = "4"
    PAYMENT_METHOD_TYPE_BANK_TRANSFER = "5"
  end

  class BaoKimPaymentPro
    def verify_response_url
      true
    end

    def get_seller_info
      params = {
        'business' => BaoKimConstant::EMAIL_BUSINESS
      }

      params = params.sort.to_h
      
      # Creating signature
      encoded_signature = create_signature('GET', BaoKimConstant::BAOKIM_API_SELLER_INFO, params, {})

      url = BaoKimConstant::BAOKIM_URL + BaoKimConstant::BAOKIM_API_SELLER_INFO
      url = url + '?' + 'signature=' + encoded_signature + '&' +  params.to_query

      res = call_api('GET', url, params)

      seller_info = JSON.parse(res.read_body)

      return seller_info['bank_payment_methods'] if seller_info['error'].blank?
      seller_info
    end

    def pay_by_card(params)
      params['business'] = BaoKimConstant::EMAIL_BUSINESS

      params = params.sort.to_h

      # Creating signature
      encoded_signature = create_signature('POST', BaoKimConstant::BAOKIM_API_PAY_BY_CARD, {}, params)

      url = BaoKimConstant::BAOKIM_URL + BaoKimConstant::BAOKIM_API_PAY_BY_CARD
      url = url + '?' + 'signature=' + encoded_signature

      res = call_api('POST', url, params)

      JSON.parse(res.read_body)
    end

    def create_signature(http_method, api_endpoint, get_params, post_params)
      private_key = OpenSSL::PKey::RSA.new File.read(BaoKimConstant::PRIVATE_KEY_BAOKIM);
      data = http_method.upcase + '&' + CGI.escape(api_endpoint) + '&' + CGI.escape(get_params.to_query) + '&' + CGI.escape(post_params.to_query)
      signature = private_key.sign(OpenSSL::Digest::SHA1.new, data)
      encoded_signature = CGI.escape(Base64.strict_encode64(signature))
    end

    def call_api(http_method, url, params)
      digest_auth = Net::HTTP::DigestAuth.new

      uri = URI.parse url
      uri.user = BaoKimConstant::API_USER
      uri.password = BaoKimConstant::API_PWD

      h = Net::HTTP.new uri.host, uri.port
      h.use_ssl = true

      if http_method == 'GET'
        req = Net::HTTP::Get.new(uri.request_uri)
        res = h.request req
        # res is a 401 response with a WWW-Authenticate header

        auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

        # create a new request with the Authorization header
        req = Net::HTTP::Get.new uri.request_uri
        req.add_field 'Authorization', auth

        # re-issue request with Authorization
        res = h.request req
      else
        req = Net::HTTP::Post.new uri.request_uri
        req.set_form_data(params)

        res = h.request req
        # res is a 401 response with a WWW-Authenticate header

        auth = digest_auth.auth_header uri, res['www-authenticate'], 'POST'

        # create a new request with the Authorization header
        req = Net::HTTP::Post.new uri.request_uri
        req.add_field 'Authorization', auth
        req.set_form_data(params)

        # re-issue request with Authorization
        res = h.request req
      end
    end
  end
end