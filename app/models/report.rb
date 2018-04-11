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

  end

  def circumcision_status

  end

  def contraindications_identified

  end

  def consent_granted

  end

  def procedures_used

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