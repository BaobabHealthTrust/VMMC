class UsersController < ApplicationController
  skip_before_filter :authenticate_user, :only => [:login, :user_authetication, :create, :reset_password]
  def login
    render layout: "form"
  end

  def user_authetication
    username = params["user"]["username"]
    password = params["user"]["password"]

    user = User.find_by_username(username)
    logged_in_user = User.authenticate(username, password)

    if logged_in_user
      session[:user] = user
      redirect_to("/") and return
    else
      flash[:error] = "Invalid username or password"
      redirect_to("/login") and return
    end

  end

  def logout
    reset_session
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
    if request.post?
      old_password = params[:user][:old_password]
      new_password = params[:user][:new_password]
      confirm_password = params[:user][:confirm_password]

      authenticate_user = User.authenticate(User.current.username, old_password)
      if authenticate_user
        if (new_password.squish != confirm_password.squish)
          flash[:error] = "New password does not match with the confirmed password"
          redirect_to("/change_password") and return
        end
        
        User.current.update_password(new_password)
        flash[:notice] = "Password updated. New password is #{new_password}"
        redirect_to("/") and return
        
      else
        flash[:error] = "Failed to change password. Old password is incorrect"
        redirect_to("/change_password") and return
      end

    end
		render layout: "full_page_form"
	end

	def edit_demographics
		render layout: "menu"
	end

  def edit_user
    @user_first_name = User.current.first_name
    @user_last_name = User.current.last_name
    if request.post?
      raise params.inspect
    end
    render layout: "full_page_form"
  end
  
	def my_profile
		render layout: false
	end

  def administration
		@tabs =  [
      ['/users','User Accounts/Settings'],
      ['/manage_location','Manage Locations'],
      ['/manage_villages', 'Manage Villages']
    ]
		render layout:false
  end
  def user
    @tabs =  [
      ['/user','Create User'],
      ['/manage_location','View users'],
      ['/manage_villages', 'Block']
    ]
		render layout:false
	end

	def manage_location
		render layout:false
	end

	def manage_villages
		render layout:false
	end
    
end
