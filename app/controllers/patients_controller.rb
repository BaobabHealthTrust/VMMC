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
  
end
