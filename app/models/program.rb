class Program < ActiveRecord::Base
  self.table_name = "program"
  self.primary_key = "program_id"

  include Openmrs
  
  belongs_to :concept, -> { where retired: 0 }
  has_many :patient_programs, -> { where voided: 0 }
  has_many :program_workflows, -> { where retired: 0 }
  has_many :program_workflow_states, :through => :program_workflows

end
