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
    return vitals if vitals_encounter.blank?
    
    (vitals_encounter.observations).each do |obs|
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

  def self.get_demographics(patient_id)
    person = Person.find(patient_id)
    data = {}
    patient_bean = PatientService.get_patient(person)
    data["name"] = patient_bean.name
    data["npid"] = patient_bean.national_id_with_dashes
    data["gender"] = patient_bean.sex
    data["age"] = patient_bean.age
    data["current_residence"] = patient_bean.current_residence
    data["traditional_authority"] = patient_bean.traditional_authority
    data["cell_phone_number"] = patient_bean.cell_phone_number
    return data
  end

  def registration_encounter_status
    patient = self
    registration_encounter_type_id = EncounterType.find_by_name("REGISTRATION").encounter_type_id
    concept_id = Concept.find_by_name("KNOWLEDGE SOURCE").concept_id
    registration_encounter = patient.encounters.joins(:observations).where(["encounter_type =? AND concept_id =?",
        registration_encounter_type_id, concept_id]).last
    return true unless registration_encounter.blank?
    return false
  end

  def has_registration_encounter
    patient = self
    registration_encounter_type_id = EncounterType.find_by_name("REGISTRATION").encounter_type_id
    concept_id = Concept.find_by_name("KNOWLEDGE SOURCE").concept_id
    registration_encounter = patient.encounters.joins(:observations).where(["encounter_type =? AND concept_id =?",
        registration_encounter_type_id, concept_id]).last
    return true unless registration_encounter.blank?
    return false
  end

  def consent_given?
    patient = self
    concept_id = Concept.find_by_name("CONSENT CONFIRMATION").concept_id
    consent_obs = patient.person.observations.joins(:encounter).where(["concept_id =? ", concept_id]).last

    unless consent_obs.blank?
      concept_answer = consent_obs.answer_string.squish.upcase
      return true if concept_answer.match(/YES/i)
      return false
    end

    return true
  end

  def patient_is_circumcised
    patient = self
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    circumcision_encounter = patient.encounters.joins(:observations).where(["encounter_type =?",
        circumcision_encounter_type_id]).last
    return true unless circumcision_encounter.blank?
    return false
  end

  def patient_is_circumcised_today(today = Date.today)
    patient = self
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    circumcision_encounter = patient.encounters.joins(:observations).where(["encounter_type =? AND
        DATE(encounter_datetime) =?", circumcision_encounter_type_id, today.to_date]).last
    return true unless circumcision_encounter.blank?
    return false
  end

  def is_patient_follow_up(today = Date.today)
    patient = self
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    circumcision_encounter = patient.encounters.joins(:observations).where(["encounter_type =? AND
        DATE(encounter_datetime) < ?", circumcision_encounter_type_id, today.to_date]).last
    return true unless circumcision_encounter.blank?
    return false
  end

  def encounter_exists_on_date(encounter_type, today = Date.today)
    patient = self
    encounter_type_id = EncounterType.find_by_name(encounter_type).encounter_type_id
    encounter = patient.encounters.joins(:observations).where(["encounter_type =? AND
        DATE(encounter_datetime) =?", encounter_type_id, today.to_date]).last
    return true unless encounter.blank?
    return false
  end

end
