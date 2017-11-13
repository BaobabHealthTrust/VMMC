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
    @links << ["Demographics (Print)","/patients/patient_demographics_label?patient_id=#{patient_id}"]
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
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream => false, :filename => "#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
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
end
