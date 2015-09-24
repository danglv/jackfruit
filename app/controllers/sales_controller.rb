class SalesController < ApplicationController
	
	# Show combo courses by code
	def combo_courses
    @combo_code = params[:combo_code]
    @courses = Sale::Services::Combo.request_courses_by_code(@combo_code)
	end

end