class PersonAddress < ActiveRecord::Base
  self.table_name = "person_address"
  self.primary_key = "person_address_id"

  belongs_to :person, :foreign_key => :person_id
end
