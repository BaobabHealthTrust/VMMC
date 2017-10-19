class EncountersController < ApplicationController
  def new
    render action: params[:encounter_type], layout: "header"
  end

  def vitals
    #@encounter_path = "/vitals?patient_id=#{params[:patient_id]}"
    render layout: "form"
  end
  
end
