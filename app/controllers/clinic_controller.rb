class ClinicController < ApplicationController

	def index
		
	end

	def set_date
		@months = [["", ""]]
  		1.upto(12){ |number| 
       		@months << [Date::MONTHNAMES[number], number.to_s]
      	}

  		day = Array.new(31){|d|d + 1 } 
    	@days = [""].concat day

    	if request.post?
    		redirect_to("/") and return
    	end

		render layout: "form"
	end

	def overview
		render layout:false
	end
end
