class PatientIdentifier < ActiveRecord::Base
  self.table_name = "patient_identifier"
  self.primary_key = "patient_identifier_id"

  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, :class_name => "Patient", :foreign_key => :patient_id
end
