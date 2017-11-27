class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  before_filter :authenticate_user, :set_work_station_location

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

  def set_work_station_location
    unless session[:workstation_location].blank?
      Location.workstation_location = session[:workstation_location]
    end
  end

  def print_and_redirect(print_url, redirect_url, message = "Printing, please wait...", show_next_button = false, patient_id = nil)
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    @patient_id = patient_id
    render template: "print/print", layout: false
  end

  def generic_locations
    field_name = "name"

    Location.find_by_sql("SELECT *
          FROM location
          WHERE location_id IN (SELECT location_id
                         FROM location_tag_map
                          WHERE location_tag_id = (SELECT location_tag_id
                                 FROM location_tag
                                 WHERE name = 'Workstation Location' LIMIT 1))
             ORDER BY name ASC").collect{|name| name.send(field_name)} rescue []
  end
end
