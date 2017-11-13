module ApplicationHelper
  def month_name_options(selected_months = [])
    i=0
    options_array = [[]] +Date::ABBR_MONTHNAMES[1..-1].collect{|month|[month,i+=1]} + [["Unknown","Unknown"]]
    options_for_select(options_array, selected_months)
  end

  def month_names
    months = [["", ""]]
    1.upto(12){ |number|
      months << [Date::MONTHNAMES[number], number.to_s]
    }
    return months
  end

  def days
    day = Array.new(31){|d|d + 1 }
    days = [""].concat day
    return days
  end

  def patient_name(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    patient_name = patient_bean.name
    return patient_name
  end

  def national_id_with_dashes(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    national_id = patient_bean.national_id_with_dashes
    return national_id
  end

  def sex(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    sex = patient_bean.sex
    return sex
  end

  def age(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    age = patient_bean.age
    return age
  end

  def current_residence(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    current_residence = patient_bean.current_residence
    return current_residence
  end

  def traditional_authority(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    traditional_authority = patient_bean.traditional_authority
    return traditional_authority
  end

  def cell_phone_number(patient_id)
    person = Person.find(patient_id)
    patient_bean = PatientService.get_patient(person)
    cell_phone_number = patient_bean.cell_phone_number
    return cell_phone_number
  end

end
