class ClinicController < ApplicationController

	def index
		@session_date = Date.today
    @user = User.find(session[:user]["user_id"])
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

	def my_account
		@my_accounts =  [
        ['/change_password','Change Password'],
        ['/edit_demographics','Edit Demographics'],
        ['/my_profile','My profile']
      ]
		render layout: false
	end

	def change_password
		render layout: false
	end

	def edit_demographics
		render layout: false
	end

	def my_profile
		render layout: false
	end

	def overview
		render layout:false
	end

	def report
		@reports =  [
        ['/first_report','First Report'],
        ['/second_report','Second Report']
      ]
		render layout:false
	end

	def first_report
		render layout: false
	end

	def second_report
		render layout:false
	end

	def administration
		@administrations =  [
        ['/user','Users'],
        ['/manage_location','Manage Locations'],
        ['/manage_villages', 'Manage Villages']
      ]
		render layout:false
	end

	def user
		render layout:false
	end

	def manage_location
		render layout:false
	end

	def manage_villages
		render layout:false
	end
end
