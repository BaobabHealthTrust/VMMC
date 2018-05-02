class Report

  attr_accessor :start_date, :end_date


	# Initialize class
	def initialize(start_date, end_date)
		@start_date = start_date
		@end_date = end_date
	end

  def age_category
    patients = Patient.circumcision_by_date_range(@start_date, @end_date)
    data = {
      "0_1" => [],
      "1_14" => [],
      "15_24" => [],
      "25_49" => [],
      "50_above" => []
    }

    patients.each do |patient|
      age_in_months = PatientService.age_in_months(patient.person)
      age = PatientService.age(patient.person)
      if age_in_months < 1
        data["0_1"] << patient.patient_id
      end

      if ((age_in_months >= 1) && age <= 14)
        data["1_14"] << patient.patient_id
      end

      if (age > 14 && age <= 24)
        data["15_24"] << patient.patient_id
      end

      if (age > 24 && age <= 49)
        data["25_49"] << patient.patient_id
      end

      if (age > 49)
        data["50_above"] << patient.patient_id
      end
    end
    
    return data
  end

  def hiv_art_status
    data = {}
    prev_positive_not_on_art_patients = Patient.prev_positive_not_on_art(@start_date, @end_date).collect{|p|p.patient_id}
    prev_positive_on_art_patients = Patient.prev_positive_on_art(@start_date, @end_date).collect{|p|p.patient_id}
    new_negatives_patients = Patient.new_negatives(@start_date, @end_date).collect{|p|p.patient_id}
    new_positives_patients = Patient.new_positives(@start_date, @end_date).collect{|p|p.patient_id}
    testing_declined_patients = Patient.testing_declined(@start_date, @end_date).collect{|p|p.patient_id}
    testing_not_done_patients = Patient.testing_not_done(@start_date, @end_date).collect{|p|p.patient_id}

    data["prev_positive_not_on_art"] = prev_positive_not_on_art_patients
    data["prev_positive_on_art"] = prev_positive_on_art_patients
    data["new_negatives"] = new_negatives_patients
    data["new_positives"] = new_positives_patients
    data["testing_declined"] = testing_declined_patients
    data["testing_not_done"] = testing_not_done_patients

    return data
  end

  def circumcision_status
    data = {}
    data["full"] = Patient.full_circumcision_status(@start_date, @end_date).collect{|p|p.patient_id}
    data["partial"] = Patient.partial_circumcision_status(@start_date, @end_date).collect{|p|p.patient_id}
    data["none"] = Patient.none_circumcision_status(@start_date, @end_date).collect{|p|p.patient_id}
    return data
  end

  def contraindications_identified
    data = {}
    data["none"] = Patient.none_contraindications(@start_date, @end_date).collect{|p|p.patient_id}
    data["yes"] = Patient.yes_contraindications(@start_date, @end_date).collect{|p|p.patient_id}
    return data
  end

  def consent_granted
    data = {}
    data["yes"] = Patient.yes_consent(@start_date, @end_date).collect{|p|p.patient_id}
    data["no"] = Patient.no_consent(@start_date, @end_date).collect{|p|p.patient_id}
    return data
  end

  def procedures_used
    data = {}
    data["forceps_guided"] = Patient.forceps_guided_procedure(@start_date, @end_date).collect{|p|p.patient_id}
    data["device"] = Patient.device_procedure(@start_date, @end_date).collect{|p|p.patient_id}
    data["others"] = Patient.other_procedures_used(@start_date, @end_date).collect{|p|p.patient_id}
    return data
  end

  def intra_operation_adverse_events

  end

  def first_review_within_48_hrs

  end

  def first_review_after_48_hrs
    
  end

  def first_review_adverse_events

  end

  def second_review_within_7_days

  end

  def second_review_adverse_events

  end

  def third_review_within_6_weeks

  end

  def third_review_adverse_events

  end

end