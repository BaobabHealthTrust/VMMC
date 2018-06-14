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

  def circumcision_consent?
    patient = self
    concept_id = Concept.find_by_name("CONTINUE TO CIRCUMCISION?").concept_id
    conset_obs = patient.person.observations.joins(:encounter).where(["concept_id =? ", concept_id]).last

    unless conset_obs.blank?
      concept_answer = conset_obs.answer_string.squish.upcase
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

  def self.circumcision_by_date_range(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    patients = []
    circumcision_encounters = Encounter.where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ?", circumcision_encounter_type_id, start_date.to_date, end_date.to_date])

    circumcision_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end
    return patients.uniq
  end

  def self.hiv_art_status(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    patients = []
    hiv_testing_encounters = Encounter.where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ?", hiv_testing_encounter_type_id, start_date.to_date, end_date.to_date])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end
    
    return patients.uniq
  end

  def self.currently_taking_arvs(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    currently_taking_arvs_concept_id = Concept.find_by_name("CURRENTLY TAKING ARVS").concept_id
    yes_concept_id = Concept.find_by_name("YES").concept_id
    patients = []
    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, currently_taking_arvs_concept_id, yes_concept_id])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.prev_positive_not_on_art(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    art_taking_patient_ids = self.currently_taking_arvs(start_date, end_date).collect{|p|p.patient_id}
    art_taking_patient_ids = [0] if art_taking_patient_ids.blank?
    reason_hiv_test_not_done_concept_id = Concept.find_by_name("REASON HIV TEST NOT DONE").concept_id
    previous_positive_concept_id = Concept.find_by_name("PREVIOUS POSITIVE").concept_id

    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =? AND patient_id NOT IN (?)", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, reason_hiv_test_not_done_concept_id, 
        previous_positive_concept_id, art_taking_patient_ids])

    patients = []
    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.prev_positive_on_art(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id

    art_taking_patient_ids = self.currently_taking_arvs(start_date, end_date).collect{|p|p.patient_id}
    art_taking_patient_ids = [0] if art_taking_patient_ids.blank?
    reason_hiv_test_not_done_concept_id = Concept.find_by_name("REASON HIV TEST NOT DONE").concept_id
    previous_positive_concept_id = Concept.find_by_name("PREVIOUS POSITIVE").concept_id

    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =? AND patient_id IN (?)", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, reason_hiv_test_not_done_concept_id,
        previous_positive_concept_id, art_taking_patient_ids])

    patients = []
    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end


  def self.new_negatives(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    result_of_hiv_test_concept_id = Concept.find_by_name("RESULT OF HIV TEST").concept_id
    negative_concept_id = Concept.find_by_name("NEGATIVE").concept_id

    patients = []
    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, result_of_hiv_test_concept_id, negative_concept_id])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.new_positives(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    result_of_hiv_test_concept_id = Concept.find_by_name("RESULT OF HIV TEST").concept_id
    positive_concept_id = Concept.find_by_name("POSITIVE").concept_id

    patients = []
    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, result_of_hiv_test_concept_id, positive_concept_id])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end
  
  def self.testing_declined(start_date, end_date)
    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    reason_hiv_test_not_done_concept_id = Concept.find_by_name("REASON HIV TEST NOT DONE").concept_id
    refused_concept_id = Concept.find_by_name("REFUSED").concept_id

    patients = []
    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, reason_hiv_test_not_done_concept_id, refused_concept_id])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.testing_not_done(start_date, end_date)

    hiv_testing_encounter_type_id = EncounterType.find_by_name("HIV TESTING").encounter_type_id
    reason_hiv_test_not_done_concept_id = Concept.find_by_name("HIV TEST DONE TODAY?").concept_id
    no_concept_id = Concept.find_by_name("NO").concept_id

    patients = []
    hiv_testing_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", hiv_testing_encounter_type_id,
        start_date.to_date, end_date.to_date, reason_hiv_test_not_done_concept_id, no_concept_id])

    hiv_testing_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
    
  end

  def self.full_circumcision_status(start_date, end_date)
    genital_examination_encounter_type_id = EncounterType.find_by_name("GENITAL EXAMINATION ").encounter_type_id
    circumcision_status_concept_id = Concept.find_by_name("CIRCUMCISION STATUS").concept_id
    full_concept_id = Concept.find_by_name("FULL").concept_id

    patients = []
    genital_examination_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", genital_examination_encounter_type_id,
        start_date.to_date, end_date.to_date, circumcision_status_concept_id, full_concept_id])

    genital_examination_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.partial_circumcision_status(start_date, end_date)
    genital_examination_encounter_type_id = EncounterType.find_by_name("GENITAL EXAMINATION ").encounter_type_id
    circumcision_status_concept_id = Concept.find_by_name("CIRCUMCISION STATUS").concept_id
    part_concept_id = Concept.find_by_name("PART").concept_id

    patients = []
    genital_examination_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", genital_examination_encounter_type_id,
        start_date.to_date, end_date.to_date, circumcision_status_concept_id, part_concept_id])

    genital_examination_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.none_circumcision_status(start_date, end_date)
    genital_examination_encounter_type_id = EncounterType.find_by_name("GENITAL EXAMINATION ").encounter_type_id
    circumcision_status_concept_id = Concept.find_by_name("CIRCUMCISION STATUS").concept_id
    none_concept_id = Concept.find_by_name("NONE").concept_id

    patients = []
    genital_examination_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", genital_examination_encounter_type_id,
        start_date.to_date, end_date.to_date, circumcision_status_concept_id, none_concept_id])

    genital_examination_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.none_contraindications(start_date, end_date)
    summary_assessment_encounter_type_id = EncounterType.find_by_name("SUMMARY ASSESSMENT").encounter_type_id
    any_contraindications_concept_id = Concept.find_by_name("ANY CONTRAINDICATIONS").concept_id
    no_concept_id = Concept.find_by_name("NO").concept_id

    patients = []
    summary_assessment_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", summary_assessment_encounter_type_id,
        start_date.to_date, end_date.to_date, any_contraindications_concept_id, no_concept_id])

    summary_assessment_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.yes_contraindications(start_date, end_date)
    summary_assessment_encounter_type_id = EncounterType.find_by_name("SUMMARY ASSESSMENT").encounter_type_id
    any_contraindications_concept_id = Concept.find_by_name("ANY CONTRAINDICATIONS").concept_id
    yes_concept_id = Concept.find_by_name("YES").concept_id

    patients = []
    summary_assessment_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", summary_assessment_encounter_type_id,
        start_date.to_date, end_date.to_date, any_contraindications_concept_id, yes_concept_id])

    summary_assessment_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.yes_consent(start_date, end_date)
    registration_encounter_type_id = EncounterType.find_by_name("REGISTRATION").encounter_type_id
    consent_confirmation_concept_id = Concept.find_by_name("CONSENT CONFIRMATION").concept_id
    yes_concept_id = Concept.find_by_name("YES").concept_id

    patients = []
    summary_assessment_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", registration_encounter_type_id,
        start_date.to_date, end_date.to_date, consent_confirmation_concept_id, yes_concept_id])

    summary_assessment_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.no_consent(start_date, end_date)
    registration_encounter_type_id = EncounterType.find_by_name("REGISTRATION").encounter_type_id
    consent_confirmation_concept_id = Concept.find_by_name("CONSENT CONFIRMATION").concept_id
    no_concept_id = Concept.find_by_name("NO").concept_id

    patients = []
    summary_assessment_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", registration_encounter_type_id,
        start_date.to_date, end_date.to_date, consent_confirmation_concept_id, no_concept_id])

    summary_assessment_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.forceps_guided_procedure(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    procedure_type_concept_id = Concept.find_by_name("PROCEDURE TYPE").concept_id
    forceps_guided_concept_id = Concept.find_by_name("FORCEPS GUIDED").concept_id

    patients = []
    circumcision_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", circumcision_encounter_type_id,
        start_date.to_date, end_date.to_date, procedure_type_concept_id, forceps_guided_concept_id])

    circumcision_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.device_procedure(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    procedure_type_concept_id = Concept.find_by_name("PROCEDURE TYPE").concept_id
    device_concept_id = Concept.find_by_name("DEVICE").concept_id

    patients = []
    circumcision_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", circumcision_encounter_type_id,
        start_date.to_date, end_date.to_date, procedure_type_concept_id, device_concept_id])

    circumcision_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.other_procedures_used(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    procedure_type_concept_id = Concept.find_by_name("PROCEDURE TYPE").concept_id
    other_concept_id = Concept.find_by_name("OTHER").concept_id

    patients = []
    circumcision_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", circumcision_encounter_type_id,
        start_date.to_date, end_date.to_date, procedure_type_concept_id, other_concept_id])

    circumcision_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.none_adverse_events(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    none_concept_id = Concept.find_by_name("NONE").concept_id

    patients = []
    post_op_review_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", post_op_review_encounter_type_id,
        start_date.to_date, end_date.to_date, adverse_concept_id, none_concept_id])

    post_op_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.mild_adverse_events(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    mild_concept_id = Concept.find_by_name("MILD").concept_id

    patients = []
    post_op_review_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", post_op_review_encounter_type_id,
        start_date.to_date, end_date.to_date, adverse_concept_id, mild_concept_id])

    post_op_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.moderate_adverse_events(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    moderate_concept_id = Concept.find_by_name("MODERATE").concept_id

    patients = []
    post_op_review_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", post_op_review_encounter_type_id,
        start_date.to_date, end_date.to_date, adverse_concept_id, moderate_concept_id])

    post_op_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.severe_adverse_events(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    severe_concept_id = Concept.find_by_name("SEVERE").concept_id

    patients = []
    post_op_review_encounters = Encounter.joins(:observations).where(["encounter_type =? AND DATE(encounter_datetime) >= ?
        AND DATE(encounter_datetime) <= ? AND concept_id =? AND value_coded =?", post_op_review_encounter_type_id,
        start_date.to_date, end_date.to_date, adverse_concept_id, severe_concept_id])

    post_op_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.first_review_within_48_hours(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    patients = []

    query = "
      SELECT * FROM encounter e1 INNER JOIN (SELECT patient_id, encounter_datetime FROM encounter WHERE
      encounter_type = #{post_op_review_encounter_type_id} AND voided = 0 ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{circumcision_encounter_type_id}
      AND e1.voided = 0 AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
      AND datediff(e2.encounter_datetime, e1.encounter_datetime) <= 2;
    "
    first_review_within_48_hours_encounters = Encounter.find_by_sql(query)

    first_review_within_48_hours_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end


  def self.first_review_after_48_hours(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    patients = []

    query = "
      SELECT * FROM encounter e1 INNER JOIN (SELECT patient_id, encounter_datetime FROM encounter WHERE
      encounter_type = #{post_op_review_encounter_type_id} AND voided = 0 ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{circumcision_encounter_type_id}
      AND e1.voided = 0 AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
      AND datediff(e2.encounter_datetime, e1.encounter_datetime) > 2;
    "
    first_review_within_48_hours_encounters = Encounter.find_by_sql(query)

    first_review_within_48_hours_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.first_review_adverse_events_none(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    none_concept_id = Concept.find_by_name("NONE").concept_id

    patients = []
    query = "
      SELECT obs.concept_id, obs.value_coded, e2.encounter_id, e1.patient_id,
				e2.encounter_datetime FROM encounter e1 INNER JOIN (
              SELECT patient_id, encounter_id, MIN(encounter_datetime) as encounter_datetime FROM encounter
              WHERE encounter_type = #{post_op_review_encounter_type_id} AND voided = 0
              AND DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}'
              GROUP by patient_id
          ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{post_op_review_encounter_type_id}
      AND e1.voided = 0
      AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      INNER JOIN obs ON obs.encounter_id = e2.encounter_id
		AND concept_id = #{adverse_concept_id} AND obs.voided = 0 AND value_coded = #{none_concept_id};
    "
    first_review_adverse_events_none_encounters = Encounter.find_by_sql(query)
    first_review_adverse_events_none_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.first_review_adverse_events_mild(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    mild_concept_id = Concept.find_by_name("MILD").concept_id

    patients = []
    query = "
      SELECT obs.concept_id, obs.value_coded, e2.encounter_id, e1.patient_id,
				e2.encounter_datetime FROM encounter e1 INNER JOIN (
              SELECT patient_id, encounter_id, MIN(encounter_datetime) as encounter_datetime FROM encounter
              WHERE encounter_type = #{post_op_review_encounter_type_id} AND voided = 0
              AND DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}'
              GROUP by patient_id
          ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{post_op_review_encounter_type_id}
      AND e1.voided = 0
      AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      INNER JOIN obs ON obs.encounter_id = e2.encounter_id
		AND concept_id = #{adverse_concept_id} AND obs.voided = 0 AND value_coded = #{mild_concept_id};
    "
    first_review_adverse_events_mild_encounters = Encounter.find_by_sql(query)
    first_review_adverse_events_mild_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.first_review_adverse_events_moderate(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    moderate_concept_id = Concept.find_by_name("MODERATE").concept_id

    patients = []
    query = "
      SELECT obs.concept_id, obs.value_coded, e2.encounter_id, e1.patient_id,
				e2.encounter_datetime FROM encounter e1 INNER JOIN (
              SELECT patient_id, encounter_id, MIN(encounter_datetime) as encounter_datetime FROM encounter
              WHERE encounter_type = #{post_op_review_encounter_type_id} AND voided = 0
              AND DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}'
              GROUP by patient_id
          ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{post_op_review_encounter_type_id}
      AND e1.voided = 0
      AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      INNER JOIN obs ON obs.encounter_id = e2.encounter_id
		AND concept_id = #{adverse_concept_id} AND obs.voided = 0 AND value_coded = #{moderate_concept_id};
    "
    first_review_adverse_events_moderate_encounters = Encounter.find_by_sql(query)
    first_review_adverse_events_moderate_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.first_review_adverse_events_severe(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    severe_concept_id = Concept.find_by_name("SEVERE").concept_id

    patients = []
    query = "
      SELECT obs.concept_id, obs.value_coded, e2.encounter_id, e1.patient_id,
				e2.encounter_datetime FROM encounter e1 INNER JOIN (
              SELECT patient_id, encounter_id, MIN(encounter_datetime) as encounter_datetime FROM encounter
              WHERE encounter_type = #{post_op_review_encounter_type_id} AND voided = 0
              AND DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}'
              GROUP by patient_id
          ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{post_op_review_encounter_type_id}
      AND e1.voided = 0
      AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      INNER JOIN obs ON obs.encounter_id = e2.encounter_id
		AND concept_id = #{adverse_concept_id} AND obs.voided = 0 AND value_coded = #{severe_concept_id};
    "
    first_review_adverse_events_severe_encounters = Encounter.find_by_sql(query)
    first_review_adverse_events_severe_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_within_7_days(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    patients = []

    query = "
      SELECT * FROM encounter e1 INNER JOIN (
        SELECT patient_id, MAX(encounter_datetime) as encounter_datetime FROM encounter WHERE
        encounter_type = #{post_op_review_encounter_type_id} AND
        DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}' AND
        voided = 0 GROUP BY patient_id HAVING COUNT(patient_id) > 1
      ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{circumcision_encounter_type_id}
      AND e1.voided = 0 AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      AND datediff(e2.encounter_datetime, e1.encounter_datetime) <= 7;
    "

    second_review_within_7_days_encounters = Encounter.find_by_sql(query)

    second_review_within_7_days_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_after_7_days(start_date, end_date)
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    patients = []

    query = "
      SELECT * FROM encounter e1 INNER JOIN (
        SELECT patient_id, MAX(encounter_datetime) as encounter_datetime FROM encounter WHERE
        encounter_type = #{post_op_review_encounter_type_id} AND
        DATE(encounter_datetime) >= '#{start_date}' AND DATE(encounter_datetime) <= '#{end_date}' AND
        voided = 0 GROUP BY patient_id HAVING COUNT(patient_id) > 1
      ) e2
      ON e1.patient_id = e2.patient_id AND e1.encounter_type = #{circumcision_encounter_type_id}
      AND e1.voided = 0 AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
      AND datediff(e2.encounter_datetime, e1.encounter_datetime) > 7;
    "

    second_review_after_7_days_encounters = Encounter.find_by_sql(query)

    second_review_after_7_days_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_adverse_events_none(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    none_concept_id = ConceptName.find_by_name("NONE").concept_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
          AND e1.encounter_type = #{post_op_review_encounter_type_id} AND e1.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_date,

        (
          SELECT encounter_id FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_id

      FROM encounter INNER JOIN obs ON obs.encounter_id = encounter.encounter_id  AND
      encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      AND concept_id = #{adverse_concept_id} AND value_coded = #{none_concept_id}
      HAVING second_review_encounter_date IS NOT NULL AND encounter.encounter_id = second_review_encounter_id;
    "
    second_review_adverse_events_none_encounters = Encounter.find_by_sql(query)
    second_review_adverse_events_none_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_adverse_events_mild(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    mild_concept_id = ConceptName.find_by_name("MILD").concept_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
          AND e1.encounter_type = #{post_op_review_encounter_type_id} AND e1.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_date,

        (
          SELECT encounter_id FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_id

      FROM encounter INNER JOIN obs ON obs.encounter_id = encounter.encounter_id  AND
      encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      AND concept_id = #{adverse_concept_id} AND value_coded = #{mild_concept_id}
      HAVING second_review_encounter_date IS NOT NULL AND encounter.encounter_id = second_review_encounter_id;
    "

    second_review_adverse_events_mild_encounters = Encounter.find_by_sql(query)
    second_review_adverse_events_mild_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_adverse_events_moderate(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    moderate_concept_id = ConceptName.find_by_name("MODERATE").concept_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
          AND e1.encounter_type = #{post_op_review_encounter_type_id} AND e1.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_date,

        (
          SELECT encounter_id FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_id

      FROM encounter INNER JOIN obs ON obs.encounter_id = encounter.encounter_id  AND
      encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      AND concept_id = #{adverse_concept_id} AND value_coded = #{moderate_concept_id}
      HAVING second_review_encounter_date IS NOT NULL AND encounter.encounter_id = second_review_encounter_id;
    "
    second_review_adverse_events_mild_encounters = Encounter.find_by_sql(query)
    second_review_adverse_events_mild_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.second_review_adverse_events_severe(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    adverse_concept_id = Concept.find_by_name("OTHER ADVERSE EVENT ACTION").concept_id
    severe_concept_id = ConceptName.find_by_name("SEVERE").concept_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND DATE(e1.encounter_datetime) >= '#{start_date}' AND DATE(e1.encounter_datetime) <= '#{end_date}'
          AND e1.encounter_type = #{post_op_review_encounter_type_id} AND e1.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_date,

        (
          SELECT encounter_id FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 1, 1
        )  as second_review_encounter_id

      FROM encounter INNER JOIN obs ON obs.encounter_id = encounter.encounter_id  AND
      encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      AND concept_id = #{adverse_concept_id} AND value_coded = #{severe_concept_id}
      HAVING second_review_encounter_date IS NOT NULL AND encounter.encounter_id = second_review_encounter_id;
    "

    second_review_adverse_events_mild_encounters = Encounter.find_by_sql(query)
    second_review_adverse_events_mild_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.third_review_within_6_weeks(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND e1.encounter_type = #{circumcision_encounter_type_id} AND e1.voided = 0 LIMIT 1
        )  as circumcision_encounter_date,

        (
          SELECT encounter_datetime FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 2, 1
        )  as third_review_encounter_date

      FROM encounter WHERE encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      HAVING third_review_encounter_date IS NOT NULL AND
      ROUND(DATEDIFF(third_review_encounter_date, circumcision_encounter_date)/7, 0) <= 6;
    "

    third_review_encounters = Encounter.find_by_sql(query)
    third_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

  def self.third_review_after_6_weeks(start_date, end_date)
    post_op_review_encounter_type_id = EncounterType.find_by_name("POST-OP REVIEW").encounter_type_id
    circumcision_encounter_type_id = EncounterType.find_by_name("CIRCUMCISION").encounter_type_id

    patients = []
    query = "
      SELECT encounter.*,
        (
          SELECT encounter_datetime FROM encounter e1 WHERE e1.patient_id = encounter.patient_id
          AND e1.encounter_type = #{circumcision_encounter_type_id} AND e1.voided = 0 LIMIT 1
        )  as circumcision_encounter_date,

        (
          SELECT encounter_datetime FROM encounter e2 WHERE e2.patient_id = encounter.patient_id
          AND DATE(e2.encounter_datetime) >= '#{start_date}' AND DATE(e2.encounter_datetime) <= '#{end_date}'
          AND e2.encounter_type = #{post_op_review_encounter_type_id} AND e2.voided = 0 LIMIT 2, 1
        )  as third_review_encounter_date

      FROM encounter WHERE encounter.encounter_type = #{post_op_review_encounter_type_id}
      AND encounter.voided = 0
      AND DATE(encounter.encounter_datetime) >= '#{start_date}' AND DATE(encounter.encounter_datetime) <= '#{end_date}'
      HAVING third_review_encounter_date IS NOT NULL AND
      ROUND(DATEDIFF(third_review_encounter_date, circumcision_encounter_date)/7, 0) > 6;
    "

    third_review_encounters = Encounter.find_by_sql(query)
    third_review_encounters.each do |encounter|
      patient = encounter.patient
      patients << patient
    end

    return patients.uniq
  end

end
