class Patient < ActiveRecord::Base
  self.table_name = "patient"
  self.primary_key = "patient_id"

  has_one :person, :foreign_key => :person_id
end
