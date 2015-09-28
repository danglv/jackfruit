class SalesController < ApplicationController
	
	# Show combo courses by code
	def combo_courses
    @combo_code = params[:combo_code]
    @combo_package = Sale::Services.get_combo(@combo_code)
	end

end