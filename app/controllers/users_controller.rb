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
      redirect_to("/work_station") and return
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
      ['/edit_demographics','Edit Demographics']#,
      #['/my_profile','My profile']
    ]
		render layout: false
  end

  def new
    @user = User.new
  end

 #  def change_password
 #    if request.post?
 #      old_password = params[:user][:old_password]
 #      new_password = params[:user][:new_password]
 #      confirm_password = params[:user][:confirm_password]

 #      authenticate_user = User.authenticate(User.current.username, old_password)
 #      if authenticate_user
 #        if (new_password.squish != confirm_password.squish)
 #          flash[:error] = "New password does not match with the confirmed password"
 #          redirect_to("/change_password") and return
 #        end
        
 #        User.current.update_password(new_password)
 #        flash[:notice] = "Password updated. New password is #{new_password}"
 #        redirect_to("/") and return
        
 #      else
 #        flash[:error] = "Failed to change password. Old password is incorrect"
 #        redirect_to("/change_password") and return
 #      end

 #    end
	# 	render layout: "full_page_form"
	# end

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

  def change_password
    @user = User.find(params[:id])

    unless request.get? 
      if (params[:user][:new_password] != params[:user][:confirm_password])
        flash[:notice] = 'Password Mismatch'
        redirect_to :action => 'new'
        return
      else
        salt = User.random_string(10)
        @user.salt = salt
        @user.password = User.encrypt(params[:user][:new_password], salt)
        if @user.save
          flash[:notice] = "Password successfully changed"
          redirect_to :action => "show",:id => @user.id
          return
        else
          flash[:notice] = "Password change failed"
        end
      end
    end
    render layout: "full_page_form"

  end
  
	def my_profile
		render layout: false
	end

  def administration
		@tabs =  [
      ['/users','User Accounts/Settings'],
      ['/manage_locations','Manage Locations']#,
      #['/manage_villages', 'Manage Villages']
    ]
		render layout:false
  end
  
  def user
    @tabs =  [
      ['/new_user','Create User'],
      ['/view_users','View users']
    ]
		render layout:false
	end

  def new_user
    if request.post?
      existing_user = User.where(["username = ?", params[:user][:username]]).first

      if existing_user
        flash[:notice] = 'Username already in use'
        redirect_to :action => '/new_user' and return
      end

      if (params[:user][:plain_password] != params[:user_confirm][:password])
        flash[:error] = 'Password Mismatch'
        redirect_to :action => '/new_user' and return
      end
      
      ActiveRecord::Base.transaction do
        person = Person.create()
        person.names.create(params[:person_name].permit!)

        salt = User.random_string(10)
        user = User.new
        user.username = params[:user][:username]
        user.salt = salt
        user.password = User.encrypt(params[:user][:plain_password], salt)
        user.person_id = person.id
        user.save
        
        user_role = UserRole.new
        user_role.role = Role.find_by_role(params[:user_role][:role_id]).role
        user_role.user_id = user.user_id
        user_role.save

      end

      flash[:notice] = 'User was successfully created.'
      redirect_to("/") and return
    end
    render layout: "full_page_form"
  end

  def view_users
    if request.post?
      user = User.find_by_username(params[:user]['username'])
      user_id = user.user_id
      redirect_to "/show/#{user_id}"
    else 
      render layout: "full_page_form"
    end
    
  end

  def show
    @user = User.find(params[:id])
    render layout: "full_page_form"
  end

  def username
    users = User.where("username LIKE '%#{params[:username]}%'")
    users = users.map{|u| "<li value='#{u.username}'>#{u.username}</li>" }
    render :text => users.join('') and return
  end

  def role
    role_conditions = ["role LIKE (?)", "%#{params[:value]}%"]
    roles = Role.where(role_conditions)
    roles = roles.map do |r|
      "<li value='#{r.role}'>#{r.role.gsub('_',' ').capitalize}</li>"
    end
    render :text => roles.join('') and return
  end

	def manage_location
		render layout:false
	end

	def manage_villages
		render layout:false
	end
    
end
