class EncountersController < ApplicationController
  def new
    @patient = Patient.last
    @min_weight = 15
    @max_weight = 100
    render action: params[:encounter_type], layout: "header"
  end

  def vitals
    @patient = Patient.last
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
