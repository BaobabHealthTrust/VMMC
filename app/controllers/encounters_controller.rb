class EncountersController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id])
    @min_weight = 15
    @max_weight = 100
    render action: params[:encounter_type], patient_id: params[:patient_id], layout: "header"
  end

  def create
    raise params.inspect
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

end
