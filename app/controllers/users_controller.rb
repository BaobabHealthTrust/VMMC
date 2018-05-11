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
    user_id = params[:id]
    user = User.find(user_id)
    @user_first_name = user.first_name
    @user_last_name = user.last_name
    @username = user.username
    
    render layout: "full_page_form"
  end

  # def update
  #   user_id = params[:id]
  #   redirect_to :action => "show", :id => user_id
  # end

  def update
    #find_by_person_id(params[:id])
    @user = User.find(params[:id])

    username = params[:user]['username'] rescue session[:user]["username"]

    if username
      @user.update_attributes(:username => username)
    end
    
    PersonName.where("voided = 0 AND person_id = #{@user.person_id}").each do | person_name |
      person_name.voided = 1
      person_name.voided_by = session[:user]["person_id"]
      person_name.date_voided = Time.now()
      person_name.void_reason = 'Edited name'
      person_name.save
    end

    person_name = PersonName.new()
    person_name.family_name = params[:person_name]["family_name"]
    person_name.given_name = params[:person_name]["given_name"]
    person_name.person_id = @user.person_id
    person_name
    if person_name.save
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user.id and return
    end

    flash[:notice] = "OOps! User was not updated!."
    render :action => 'show', :id => @user.id
  end

  def change_password
    @user = User.find(params[:id])

    unless request.get? 
      if (params[:user][:new_password] != params[:user][:confirm_password])
        flash[:notice] = 'Password Mismatch'
        redirect_to "/user/change_password?id=#{params[:id]}"
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
        redirect_to :action => 'new_user' and return
      end

      if (params[:user][:plain_password] != params[:user_confirm][:password])
        flash[:error] = 'Password Mismatch'
        redirect_to :action => 'new_user' and return

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


      flash[:notice] = 'User was successfully created.'
      redirect_to("/show/#{user.user_id}") and return

      end rescue redirect_to "/new_user" and return

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
      next unless r.role.match(/clinician|nurse|clerk|doctor|provider/i)
      next if r.role.match(/spine|feeding|general|vitals/i)
      "<li value='#{r.role}'>#{r.role.gsub('_',' ').capitalize}</li>"
    end
    render :text => roles.join('') and return
  end

  def change_role
    @user = User.find(params[:id])
    render layout: "full_page_form"
  end

  def update_role
    @user = User.find(params[:id])
    user_role = @user.user_role
    user_role.role = params[:user_role][:role]
    if user_role.save
      redirect_to "/show/#{params[:id]}"
    else 
       flash[:notice] = "Error on updating the User Role"
       redirect_to "/user/change_role?id=#{params[:id]}"
    end   
  end

	def manage_location
		render layout:false
	end

	def manage_villages
		render layout:false
	end
    
end
