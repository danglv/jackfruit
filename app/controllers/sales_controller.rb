class SalesController < ApplicationController

  # Show combo courses by code
  def detail
    combo_code = params[:combo_code]
    @combo_package = Sale::Services.get_combo(combo_code)

    if request.headers['Accept'] == 'json'
      result = @combo_package.blank? \
                ? {'error': "Mã combo #{combo_code} không hợp lệ"} \
                : SalePackageSerializer.new(@combo_package)
      render json: result
      return
    end
  end

end