class EncountersController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id])
    @min_weight = 15
    @max_weight = 100
    render action: params[:encounter_type], patient_id: params[:patient_id], layout: "header"
  end

  def create
    session = Date.today
    patient_id = params[:encounter][:patient_id]
    if params[:encounter]["encounter_type_name"].squish.upcase == 'VITALS'
      create_vitals_encounter(params, session)
      url = "/patients/show/#{patient_id}"
      redirect_to url and return
    end
  end
  
  def vitals
    @patient = Patient.find(params["patient_id"])
    render layout: "form"
  end

  def medical_history
    @patient = Patient.last
    render layout: "form"
  end

  def hiv_art_status
    @patient = Patient.last
    render layout: "form"
  end

  def genital_examination
    @patient = Patient.last
    render layout: "form"
  end

  def circumcision
    @patient = Patient.last
    render layout: "form" 
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
					if observation[:concept_name].humanize == "Tests ordered"
						#observation[:accession_number] = Observation.new_accession_number
					end

					observation = update_observation_value(observation)

					Observation.create(observation)
				end
			elsif extracted_value_numerics.class == Array
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric

				  if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
						observation[:value_text] = observation[:value_numeric]
						observation.delete(:value_numeric)
					end

					Observation.create(observation)
				end
			else
				observation.delete(:value_coded_or_text_multiple)
				observation = update_observation_value(observation) if !observation[:value_coded_or_text].blank?

				if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
					observation[:value_text] = observation[:value_numeric]
					observation.delete(:value_numeric)
				end

				Observation.create(observation)
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
