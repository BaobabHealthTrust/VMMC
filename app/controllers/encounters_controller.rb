class EncountersController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id])
    @min_weight = 15
    @max_weight = 100
    @medical_history_options = medical_history_options
    @diabetes_types = diabetes_types
    @circumcision_options = circumcision_options
    @anaesthesia_types = anaesthesia_options
    @anaesthesia = anaesthesia
    @anaesthesia_measurement = anaesthesia_measurement
    @circumcision_procedure_types = circumcision_procedure_types
    @pain_options = pain_options
    @bandage_options = bandage_options
    @other_ae_options = other_ae_options
    @contraindications = contraindications
    @services_sources = service_sources_options
    @hiv_test_not_done_reasons = hiv_test_not_done_reasons_options
    @hiv_results_options = hiv_results_option
    @max_date = max_date
    @haematoma_options = haematoma_options
    @swelling_options = swelling_options
    @glans_damage_options = glans_damage_options
    @infection_options = infection_options
    @wound_disruption_options = wound_disruption_options
    @urinary_problem_options = urinary_problem_options
    @yes_no_options = yes_no_options
    @none_mild_mod_sev_options = none_mild_mod_sev_options
    @side_effects_array = ["Pain", "Bleeding", "Haematoma","Swelling", "Damage to glans", "Infection", "Wound Disruption", "Urinary problems"]

    render action: params[:encounter_type], patient_id: params[:patient_id], layout: "header"
  end

  def create
    session_datetime = session[:session_date].to_date rescue Date.today
    patient_id = params[:encounter][:patient_id]
    person = Person.find(patient_id)

    encounter_type = EncounterType.find_by_name(params[:encounter]["encounter_type_name"])
    patient_id = params[:encounter]["patient_id"].to_i

    begin
      encounter_datetime = session_datetime.strftime('%Y-%m-%d 00:00:01')
      params[:encounter]['encounter_datetime'] = encounter_datetime
    rescue
      encounter_datetime = params[:encounter]['encounter_datetime'].to_time.strftime('%Y-%m-%d %H:%M:%S') rescue nil
      if encounter_datetime.blank?
        encounter_datetime = Time.now().strftime('%Y-%m-%d %H:%M:%S')
        params[:encounter]['encounter_datetime'] = encounter_datetime
      end
    end

    ActiveRecord::Base.transaction do
      encounter = Encounter.create(
        :patient_id => patient_id,
        :encounter_datetime => encounter_datetime,
        :encounter_type => encounter_type.id)

      create_obs(encounter, params)
    end

    url = next_task(person).url
    redirect_to url and return
      
  end

  def registration
    @patient = Patient.find(params[:patient_id])
    @services_sources = service_sources_options
    render layout: "form"
  end
  
  def service_sources_options
    options = [
      ["", ""],
      ["Friend", "Friend"],
      ["Family", "Family"],
      ["Partner/Spouse", "Partner or Spouse"],
      ["Health care worker", "Health care worker"],
      ["Poster/Newspaper/Leaflet", "Poster/Newspaper/Leaflet"],
      ["Community Mobiliser", "Community Mobiliser"],
      ["Television/Radio", "Television/Radio"],
      ["Other", "Other"]
    ]
    return options
  end

  def vitals
    @patient = Patient.find(params["patient_id"])
    render layout: "form"
  end

  def medical_history
    @patient = Patient.find(params["patient_id"])
    @medical_history_options = medical_history_options
    @diabetes_types = diabetes_types
    @yes_no_options = yes_no_options
    render layout: "form"
  end

  def circumcision_options
    options = [["",""], ["Full", "Full"], ["Part", "Part"], ["None", "None"]]
    return options
  end

  def medical_history_options
    options = [
      "",
      "None",
      "Diabetes",
      "Bleeding disorder",
      "Any meds",
      "Allergies",
      "Genital ulcers",
      "Genital itching",
      "Painful urination",
      "Other"
    ]
    return options
  end

  def diabetes_types
    options = [
      ["", ""],
      ["Type 1 diabetes", "Type 1 diabetes"],
      ["Type 2 diabetes", "Type 2 diabetes"],
      ["Unknown", "Unknown"]
    ]
    return options
  end

  def hiv_art_status
    @patient = Patient.find(params["patient_id"])
    @hiv_test_not_done_reasons = hiv_test_not_done_reasons_options
    @hiv_results_options = hiv_results_option
    render layout: "form"
  end

  def hiv_results_option
    options = [
      ["", ""],
      ["Positive", "Positive"],
      ["Negative", "Negative"],
      ["Indeterminate", "Indeterminate"]
    ]
    return options
  end

  def hiv_test_not_done_reasons_options
    options = [
      ["", ""],
      ["Refused", "Refused"],
      ["Previous Positive", "Previous Positive"],
      ["No Reagents available", "No Reagents available"]
    ]
    return options
  end

  def contraindications
    options = [
      ["", ""],
      ["Active or symptomatic STIs", "Active or symptomatic STIs"],
      ["Hypertension", "Hypertension"],
      ["Diabetes", "Diabetes"],
      ["Bleeding disorders", "Bleeding disorders"],
      ["Erectile dysfunction", "Erectile dysfunction"],
      ["Anatomical deformities of the penis e.g. hypospodiasis", "Anatomical deformities of the penis e.g. hypospodiasis"],
      ["Chronic paraphimosis", "Chronic paraphimosis"],
      ["Penile cancer", "Penile cancer"],
      ["Other chronic disorders of the penis e.g. filariasis", "Other chronic disorders of the penis e.g. filariasis"]
    ]
    return options
  end

  def genital_examination
    @patient = Patient.find(params["patient_id"])
    @circumcision_options = circumcision_options
    @yes_no_options = yes_no_options
    render layout: "form"
  end

  def summary_assessment
    @patient = Patient.find(params["patient_id"])
    @yes_no_options = yes_no_options
    @max_date = max_date
    @contraindications = contraindications
    render layout: "form"
  end

  def circumcision
    @patient = Patient.find(params["patient_id"])
    @anaesthesia_types = anaesthesia_options
    @anaesthesia = anaesthesia
    @anaesthesia_measurement = anaesthesia_measurement
    @circumcision_procedure_types = circumcision_procedure_types
    @max_date = max_date
    render layout: "form" 
  end

  def max_date
    today = Date.today
    max_date = today + 3.months
    max_date = max_date.strftime("%Y-%m-%d")
    return max_date
  end

  def post_op_review
    @patient = Patient.find(params["patient_id"])
    @pain_options = pain_options
    @bandage_options = bandage_options
    @other_ae_options = other_ae_options
    @max_date = max_date
    render layout: "form" 
  end

  def follow_up_review
    @patient = Patient.find(params["patient_id"])
    @pain_options = pain_options
    @bandage_options = bandage_options
    @other_ae_options = other_ae_options
    @haematoma_options = haematoma_options
    @swelling_options = swelling_options
    @glans_damage_options = glans_damage_options
    @infection_options = infection_options
    @wound_disruption_options = wound_disruption_options
    @urinary_problem_options = urinary_problem_options
    @yes_no_options = yes_no_options
    @none_mild_mod_sev_options = none_mild_mod_sev_options
    @side_effects_array = ["Pain", "Bleeding", "Haematoma","Swelling", "Damage to glans", "Infection", "Wound Disruption", "Urinary problems"]
    render layout: "form" 
  end

  def none_mild_mod_sev_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def yes_no_options
    options = [
      ["", ""],
      ["Yes", "Yes"],
      ["No", "No"]
    ]
    return options
  end

  def urinary_problem_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def wound_disruption_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def infection_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def glans_damage_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def swelling_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def haematoma_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def pain_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def bandage_options
    options = [
      ["", ""],
      ["Dry", "Dry"],
      ["Spot", "Spot"],
      ["Soak", "Soak"]
    ]
    return options
  end

  def other_ae_options
    options = [
      ["", ""],
      ["None", "None"],
      ["Mild", "Mild"],
      ["Moderate", "Moderate"],
      ["Severe", "Severe"]
    ]
    return options
  end

  def anaesthesia_options
    options = [
      ["", ""],
      ["Local Anaesthesia (LA)", "Local Anaesthesia"],
      ["General Anaesthesia (GA)", "General Anaesthesia"]
    ]
    return options
  end

  def anaesthesia
    options = [
      ["", ""],
      ["Lidocaine", "Lidocaine"],
      ["Bupivacaine", "Bupivacaine"]
    ]
    return options
  end

  def anaesthesia_measurement
    options = [
      ["", ""],
      ["Percentage (%)", "Percent"],
      ["Milliliter (mls)", "mls"]
    ]
    return options
  end

  def circumcision_procedure_types
    options = [
      ["", ""],
      ["Forceps Guided (FG)", "Forceps Guided"],
      ["Dorsal Slit (DS)", "Dorial Slit"],
      ["Device", "Device"],
      ["Other", "Other"]
    ]
    return options
  end

  def void
    encounter = Encounter.find(params[:encounter_id])
    encounter.void
    render text: 'success' and return
  end
  
  def details
    @patient_encounters_on_date = Patient.get_encounters_on_date(params[:patient_id], params[:encounter_date])
    render layout: false
  end

  def observations
    encounter = Encounter.find(params[:encounter_id])
    encounter_type = encounter.type.name
    observations = encounter.observations
    data = {}
    observations.each do |obs|
      obs_id = obs.obs_id
      data[obs_id] = {}
      data[obs_id]["concept"] = obs.concept.fullname
      data[obs_id]["answer"] = obs.answer_string.squish
      data[obs_id]["encounter_type"] = encounter_type
    end
    
    render text: data.to_json and return
  end

  def create_vitals_encounter(params, session)
    encounter_type = EncounterType.find_by_name('VITALS')
    patient_id = params[:encounter]["patient_id"].to_i
    begin
      encounter_datetime = session[:datetime].to_date.strftime('%Y-%m-%d 00:00:01')
      params[:encounter]['encounter_datetime'] = encounter_datetime
    rescue
      encounter_datetime = params[:encounter]['encounter_datetime'].to_time.strftime('%Y-%m-%d %H:%M:%S') rescue nil
      if encounter_datetime.blank?
        encounter_datetime = Time.now().strftime('%Y-%m-%d %H:%M:%S')
        params[:encounter]['encounter_datetime'] = encounter_datetime
      end
    end

    encounter = Encounter.create(
      :patient_id => patient_id,
      :encounter_datetime => encounter_datetime,
      :encounter_type => encounter_type.id)

    create_obs(encounter, params)

  end

  def create_obs(encounter , params)
		(params[:observations] || []).each do |observation|
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map { |value_name|
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact

      values = values.flatten.reject { |v| v.empty? }
			next if values.length == 0
			observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
			observation[:person_id] ||= encounter.patient_id

			# Handle multiple select

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(String)
				observation[:value_coded_or_text_multiple] = observation[:value_coded_or_text_multiple].split(';')
			end

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
				observation[:value_coded_or_text_multiple].compact!
				observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
			end

			# convert values from 'mmol/litre' to 'mg/declitre'
			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(!observation[:parent_concept_name].blank?)
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
        observation[:obs_group_id] = Observation.where(['concept_id = ? AND encounter_id = ?', concept_id, encounter.id]
        ).order("obs_id ASC, date_created ASC").last.id rescue ""

				observation.delete(:parent_concept_name)
			else
				observation.delete(:parent_concept_name)
				observation.delete(:obs_group_id)
			end

			extracted_value_numerics = observation[:value_numeric]
			extracted_value_coded_or_text = observation[:value_coded_or_text]


			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
				values = observation.delete(:value_coded_or_text_multiple)
				values.each do |value|
					observation[:value_coded_or_text] = value
          #raise observation[:concept_name].inspect
					#if observation[:concept_name].humanize == "Tests ordered"
          #observation[:accession_number] = Observation.new_accession_number
					#end
          observation = update_observation_value(observation)

          observation = observation.permit!
          obs = Observation.new(observation)
          
          obs.save

				end
			elsif extracted_value_numerics.class == Array
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric

				  if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
						observation[:value_text] = observation[:value_numeric]
						observation.delete(:value_numeric)
					end
   
					observation = observation.permit! #Rails 4 hack
          obs = Observation.new(observation)
          obs.save
				end
			else
				observation.delete(:value_coded_or_text_multiple)
				observation = update_observation_value(observation) if !observation[:value_coded_or_text].blank?

				if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
					observation[:value_text] = observation[:value_numeric]
					observation.delete(:value_numeric)
				end

        observation = observation.permit!
				obs = Observation.new(observation)
        obs.save
			end
		end
	end

  def update_observation_value(observation)
		value = observation[:value_coded_or_text]
		value_coded_name = ConceptName.find_by_name(value)

		if value_coded_name.blank?
			observation[:value_text] = value
		else
			observation[:value_coded_name_id] = value_coded_name.concept_name_id
			observation[:value_coded] = value_coded_name.concept_id
		end
		observation.delete(:value_coded_or_text)
		return observation
	end
  
end
