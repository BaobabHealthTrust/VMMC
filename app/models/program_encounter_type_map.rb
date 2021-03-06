class ProgramEncounterTypeMap < ActiveRecord::Base
  self.table_name = "program_encounter_type_map"
  self.primary_key = "program_encounter_type_map_id"
  belongs_to :program, -> { where retired: 0 }
  belongs_to :encounter_type, -> { where retired: 0 }

  include Openmrs
  
end
