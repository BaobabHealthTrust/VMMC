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
    
    patient = person.patient
    today = session[:session_date].to_date rescue Date.today
    user = User.find(session[:user]["user_id"]) rescue ""
    use_role = user.user_role.role rescue ""

    if (patient.consent_given? == true)
      if patient.is_patient_follow_up(today)
        if !patient.encounter_exists_on_date("FOLLOW UP", today)
          task.url = "/encounters/new?encounter_type=follow_up_review&patient_id=#{patient.patient_id}"
          task.name = "Follow Up"
          return task if !use_role.match(/clerk/i)
        else
          task.url = "/patients/show/#{person.person_id}"
          task.name = "None"
          return task
        end
      else
        if !patient.has_registration_encounter
          task.url = "/encounters/new?encounter_type=registration&patient_id=#{patient.patient_id}"
          task.name = "Registration"
          return task
        else
          if !patient.encounter_exists_on_date("MEDICAL HISTORY", today)
            task.url = "/encounters/new?encounter_type=medical_history&patient_id=#{patient.patient_id}"
            task.name = "Medical History"
            return task if !use_role.match(/clerk/i)
          end

          if !patient.encounter_exists_on_date("VITALS", today)
            task.url = "/encounters/new?encounter_type=vitals&patient_id=#{patient.patient_id}"
            task.name = "Vital Signs"
            return task
          end

          if !patient.encounter_exists_on_date("HIV Testing", today)
            task.url = "/encounters/new?encounter_type=hiv_art_status&patient_id=#{patient.patient_id}"
            task.name = "HIV Testing"
            return task if !use_role.match(/clerk/i)
          end

          if !patient.encounter_exists_on_date("GENITAL EXAMINATION", today)
            task.url = "/encounters/new?encounter_type=genital_examination&patient_id=#{patient.patient_id}"
            task.name = "Genital Examination"
            return task if !use_role.match(/clerk/i)
          end

          if !patient.encounter_exists_on_date("SUMMARY ASSESSMENT", today)
            task.url = "/encounters/new?encounter_type=summary_assessment&patient_id=#{patient.patient_id}"
            task.name = "Summary Assessment"
            return task if !use_role.match(/clerk/i)
          end

          if !patient.encounter_exists_on_date("CIRCUMCISION", today)
            task.url = "/encounters/new?encounter_type=circumcision&patient_id=#{patient.patient_id}"
            task.name = "Circumcision"
            return task if !use_role.match(/clerk/i)
          end

          if !patient.encounter_exists_on_date("POST-OP REVIEW", today)
            task.url = "/encounters/new?encounter_type=post_op_review&patient_id=#{patient.patient_id}"
            task.name = "Post-OP Review"
            return task if !use_role.match(/clerk/i)
          end
        end
      end
    end
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
