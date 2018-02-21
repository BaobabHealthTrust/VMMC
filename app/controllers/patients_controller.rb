class PatientsController < ApplicationController

	def new_patient
    render layout: "form"
	end

  def show
    person = Person.find (params[:patient_id])
    @session_date =  (session[:session_date].to_date rescue Date.today).strftime("%d %b, %Y")
    @patient_bean = PatientService.get_patient(person)
  end

  def header

  end

  def activities
    patient_id = params[:patient_id]
    @links = []
    @links << ["Demographics (Edit)","/edit_demographics/#{patient_id}"]
    @links << ["Demographics (Print)","/patients/patient_demographics_label?patient_id=#{patient_id}"]
    @links << ["Visit Summary (Print)","/patients/visit_summary_label?patient_id=#{patient_id}"]
    @links << ["National ID (Print)","/patients/national_id_label?patient_id=#{patient_id}"]
    
    render layout: false
  end

  def edit_demographics
    patient = Patient.find(params[:patient_id])
    @bean = PatientService.get_patient(patient.person)
    render layout: "menu"
  end

  def update_demographics
    patient = Patient.find(params[:patient_id])
    person = patient.person
    @bean = PatientService.get_patient(person)
    if request.post?
      if (params[:field] == 'first_name' || params[:field] == 'last_name')
        person.names.last.update_attributes(params["person"]["names"].permit!)
      end

      if (params[:field] == 'date_of_birth')
        if params["person"]["birth_year"] == "Unknown"
          PatientService.set_birthdate_by_age(person, params["person"]['age_estimate'], Date.today)
        else
          PatientService.set_birthdate(person, params["person"]["birth_year"], params["person"]["birth_month"], params["person"]["birth_day"])
        end
        patient.person.save
      end

      if (params[:field] == 'address' || params[:field] == 'land_mark')
        person.addresses.last.update_attributes(params["person"]["addresses"].permit!)
      end

      if (params[:field] == 'cell_phone_number')
        person_attribute_type_id = PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id
        person_attribute = person.person_attributes.find_by_person_attribute_type_id(person_attribute_type_id)

        if person_attribute.blank?
          person.person_attributes.create(
            :person_attribute_type_id => person_attribute_type_id,
            :value => params["person"]["cell_phone_number"])
        else
          person_attribute.update_attributes(value: params["person"]["cell_phone_number"])
        end
		
      end
      
      redirect_to("/edit_demographics/#{params[:patient_id]}") and return
    end
    render layout: "full_page_form"
  end

  def get_patient_visits
    recent_encounters = Patient.recent_encounters(params[:patient_id])
    data = {}
    recent_encounters.each do |encounter|
      encounter_id = encounter.encounter_id
      data[encounter_id] = {}
      data[encounter_id]["encounter_date"] = encounter.encounter_datetime.to_date.strftime("%d/%b/%Y")
    end
    render :text => data.to_json
  end

  def get_patient_vitals
    recent_patient_vitals = Patient.recent_vitals(params[:patient_id])
    render text: recent_patient_vitals.to_json and return
  end

  def national_id_label
    patient = Patient.find(params[:patient_id])
    print_string = PatientService.patient_national_id_label(patient) rescue "Error"
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream => false, :filename => "#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def visit_summary_label
    patient = Patient.find(params[:patient_id])
    print_string = generate_visit_summary_label(patient)
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream => false, :filename => "#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def generate_visit_summary_label(patient)
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 50
    session_date = session[:session_date].to_date rescue Date.today
    todays_encounters = patient.encounters.where(["DATE(encounter_datetime) = ?", session_date])
    return nil if todays_encounters.blank?

    label.draw_multi_text("Visit: #{session_date.strftime("%d/%b/%Y %H:%M")}", :font_reverse => true)

    todays_encounters.each do |encounter|
      next if encounter.type.name.upcase == "REGISTRATION"
      encounter.observations.each do |obs|
        answer_string = obs.answer_string.squish
        concept_name = obs.concept.shortname
        label.draw_multi_text("#{concept_name}: #{answer_string}", :font_reverse => false)
      end
    end

    label.print(1)
  end
  
  def patient_demographics_label
    print_string = demographics_label(params[:patient_id])
    send_data(print_string, :type=>"application/label; charset=utf-8", :stream => false, :filename => "#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def demographics_label(patient_id)
    patient = Patient.find(patient_id)
    patient_bean = PatientService.get_patient(patient.person)
    label = ZebraPrinter::StandardLabel.new
    label.draw_text("Printed on: #{Date.today.strftime('%A, %d-%b-%Y')}",450,300,0,1,1,1,false)
    label.draw_text("PATIENT DETAILS",25,30,0,3,1,1,false)
    label.draw_text("Name:   #{patient_bean.name} (#{patient_bean.sex})",25,60,0,3,1,1,false)
    label.draw_text("DOB:    #{patient_bean.birth_date}",25,90,0,3,1,1,false)
    label.draw_text("Phone: #{patient_bean.cell_phone_number}",25,120,0,3,1,1,false)
    label.print(1)
  end

  def get_demographics
    demographics = Patient.get_demographics(params[:patient_id])
    render text: demographics.to_json and return
  end

  def get_registration_encounter_status
    patient = Patient.find(params[:patient_id])
    registration_encounter_status = patient.registration_encounter_status
    render text: registration_encounter_status.to_s and return
  end

  def patient_is_circumcised
    patient = Patient.find(params[:patient_id])
    circumcision_status = patient.patient_is_circumcised
    render text: circumcision_status.to_s and return
  end

  def patient_is_circumcised_today
    patient = Patient.find(params[:patient_id])
    session_date =  session[:session_date].to_date rescue Date.today
    circumcised_today_status = patient.patient_is_circumcised_today(session_date)
    render text: circumcised_today_status.to_s and return
  end

  def get_follow_up_status
    patient = Patient.find(params[:patient_id])
    session_date =  session[:session_date].to_date rescue Date.today
    follow_up_status = patient.is_patient_follow_up(session_date)
    render text: follow_up_status.to_s and return
  end

  def check_if_encounter_exists_on_date
    encounter_type = params[:encounter_type]
    patient = Patient.find(params[:patient_id])
    session_date =  session[:session_date].to_date rescue Date.today
    encounter_status = patient.encounter_exists_on_date(encounter_type, session_date)
    render text: encounter_status.to_s and return
  end

  def get_next_task
    patient = Patient.find(params[:patient_id])
    task_name = next_task(patient.person).name
    render text: task_name.to_s and return
  end

  def patient_consent_given
    patient = Patient.find(params[:patient_id])
    consent_given = patient.consent_given?
    render text: consent_given.to_s and return
  end

  def patient_circumcision_consent
    patient = Patient.find(params[:patient_id])
    continue_to_circumcision = patient.circumcision_consent?
    render text: continue_to_circumcision.to_s and return
  end

  def get_user_role
    user = User.find(session[:user]["user_id"])
    use_role = user.user_role.role rescue ""
    render text: use_role.to_s and return
  end

end
