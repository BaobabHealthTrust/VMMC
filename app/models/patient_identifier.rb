class PatientIdentifier < ActiveRecord::Base
  self.table_name = "patient_identifier"
  self.primary_key = "patient_identifier_id"

  include Openmrs
  
  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, :class_name => "Patient", :foreign_key => :patient_id

  def self.calculate_checkdigit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      digit = digit * 2 if index%2==parity
      digit = digit - 9 if digit > 9
      sum = sum + digit
    end

    checkdigit = 0
    checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0
    return checkdigit
  end

  def self.site_prefix
    site_prefix = GlobalProperty.find_by_property("site_prefix").property_value rescue ''
    return site_prefix
  end

  def self.dde_code
    dde_code = GlobalProperty.find_by_property("dde.code").property_value rescue ''
    return dde_code
  end


  def self.identifier(patient_id, patient_identifier_type_id)
    patient_identifier = self.find(:first, :select => "identifier",
      :conditions  =>["patient_id = ? and identifier_type = ?", patient_id, patient_identifier_type_id])
    return patient_identifier
  end

end
