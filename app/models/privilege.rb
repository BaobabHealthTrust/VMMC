class Privilege < ActiveRecord::Base
  self.table_name = "privilege"
  self.primary_key = "privilege"

  has_many :role_privileges, :foreign_key => :privilege, :dependent => :delete_all # no default scope
  has_many :roles, :through => :role_privileges # no default scope

  
end
