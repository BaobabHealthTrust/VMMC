class RelationshipType < ActiveRecord::Base
  self.table_name = "relationship_type"
  self.primary_key = "relationship_type_id"
  default_scope :order => 'weight DESC'
  has_many :relationships#, :conditions => {:voided => 0}

end
