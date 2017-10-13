class ClinicController < ApplicationController

	def index
		
	end

	def set_date
		@months = "<option>" "" "</option>"
  		1.upto(12){ |number| 
       		@months += "<option value = '" + number.to_s + "'>" + Date::MONTHNAMES[number] + "</option>"
      	}
      	@months << "<option>" "Unknown" "</option>"
  
  		day = Array.new(31){|d|d + 1 } 
    	@days = [""].concat day

		render layout: "form"
	end
end
