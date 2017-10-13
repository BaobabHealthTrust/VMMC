class UsersController < ApplicationController

def login
	render layout: "form"
  
  end

  def user_authetication
  	redirect_to("/") and return
  end          
end
