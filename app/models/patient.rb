class Patient < ActiveRecord::Base
  self.table_name = "patient"
  self.primary_key = "patient_id"

  before_create :before_create
  before_save :before_save

  include Openmrs
  
  has_one :person, :foreign_key => :person_id#, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy#, :conditions => {:voided => 0}
  has_many :patient_programs#, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy#, :conditions => {:voided => 0}
  has_many :encounters#, :conditions => {:voided => 0}

  def before_save
    self.changed_by = User.current.user_id unless User.current.blank?
    self.date_changed = Time.now
  end

  def before_create
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
  end

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

  def self.recent_vitals(patient_id)
    vitals_encounter_type_id = EncounterType.find_by_name("VITALS").encounter_type_id
    vitals_encounter = Encounter.where(["patient_id =? AND encounter_type =?", patient_id, vitals_encounter_type_id]).last
    vitals = {}
    
    vitals_encounter.observations.each do |obs|
      concept_fullname = obs.concept.fullname
      answer_string = obs.answer_string.squish
      vitals["sbp"] = answer_string if concept_fullname.match(/SYSTOLIC BLOOD PRESSURE/i)
      vitals["dbp"] = answer_string if concept_fullname.match(/DIASTOLIC BLOOD PRESSURE/i)
      vitals["temp"] = answer_string if concept_fullname.match(/TEMPERATURE/i)
      vitals["bmi"] = answer_string if concept_fullname.match(/BMI/i)
      vitals["weight"] = answer_string if concept_fullname.match(/WEIGHT/i)
      vitals["height"] = answer_string if concept_fullname.match(/HEIGHT/i)
    end

    return vitals
  end

end
