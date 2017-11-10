class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  before_filter :authenticate_user

  def authenticate_user
    user = User.find(session[:user]["user_id"]) rescue nil
    unless user.blank?
      User.current = user
      return true
    end
    access_denied
    return false
  end

  def access_denied
    redirect_to ("/login") and return
  end

  def next_task(person)
    task = OpenStruct.new
    task.url = "/patients/show/#{person.person_id}"
    task.name = "None"
    return task
  end

end
