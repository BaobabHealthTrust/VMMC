class UsersController < ApplicationController

  def login
    render layout: "form"
  end

  def user_authetication
  	redirect_to("/") and return
  end

  def logout
  	redirect_to("/login") and return
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
