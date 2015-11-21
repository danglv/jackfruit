module CodServices extend ActiveSupport::Concern
  def check_activation_code(activation_code)
    response = RestClient.get('http://code.pedia.vn/cod/detail', {
      params: {
        cod: activation_code
      }, 
      accept: :json
    }) { |response, request, result, &block|
      data = JSON.parse(response)
      case result.code
      when "200"
        return true, data
      else
        return false, data['message']
      end
    }
  end
end