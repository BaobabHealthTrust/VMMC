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
end
