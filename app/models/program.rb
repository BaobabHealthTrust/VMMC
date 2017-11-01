class Program < ActiveRecord::Base
  self.table_name = "program"
  self.primary_key = "program_id"

  belongs_to :concept#, :conditions => {:retired => 0}
  has_many :patient_programs#, :conditions => {:voided => 0}
  has_many :program_workflows#, :conditions => {:retired => 0}
  has_many :program_workflow_states, :through => :program_workflows

end
