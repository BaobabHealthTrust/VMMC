class EncounterType < ActiveRecord::Base
  self.table_name = "encounter_type"
  self.primary_key = "encounter_type_id"

  include Openmrs
  
  has_many :encounters#, :conditions => {:voided => 0}
end
