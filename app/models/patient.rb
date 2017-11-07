class Patient < ActiveRecord::Base
  self.table_name = "patient"
  self.primary_key = "patient_id"

  include Openmrs
  
  has_one :person, :foreign_key => :person_id#, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy#, :conditions => {:voided => 0}
  has_many :patient_programs#, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy#, :conditions => {:voided => 0}
  has_many :encounters#, :conditions => {:voided => 0}

  def name
    "#{self.person.names[0].given_name rescue ''} #{self.person.names[0].family_name rescue ''}"
  end

  def self.recent_encounters(patient_id)
   recent_encounters =  Encounter.where(["patient_id =?", patient_id]).order("DATE(encounter_datetime) DESC").group("DATE(encounter_datetime)")
   return recent_encounters
  end

  def self.get_encounters_on_date(patient_id, encounter_date)
    patient_encounters_on_date = Encounter.where(["patient_id =? AND DATE(encounter_datetime) =?", patient_id, encounter_date.to_date]).order("DATE(encounter_datetime) DESC")
    return patient_encounters_on_date
  end

end
