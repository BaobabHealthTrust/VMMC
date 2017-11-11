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

  def activities
    patient_id = params[:patient_id]
    @links = []
    @links << ["Demographics (Edit)","/"]
    @links << ["Demographics (Print)","/"]
    @links << ["Visit Summary (Print)","/"]
    @links << ["National ID (Print)","/patients/national_id_label?patient_id=#{patient_id}"]
    
    render layout: false
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
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

end
