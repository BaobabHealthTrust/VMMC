class UserProperty < ActiveRecord::Base
  self.table_name = "user_property"
  self.primary_keys = :user_id, :property

  include Openmrs
end
