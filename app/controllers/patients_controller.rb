class PatientsController < ApplicationController

	def new_patient
    render layout: "form"
	end

  def show
    person = Person.find (params[:patient_id])
    @patient_bean = PatientService.get_patient(person)
  end

  def header

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
  
end
