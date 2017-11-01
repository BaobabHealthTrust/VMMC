class Relationship < ActiveRecord::Base
  self.table_name = "relationship"
  self.primary_key = "relationship_id"

  belongs_to :person, :class_name => 'Person', :foreign_key => :person_a#, :conditions => {:voided => 0}
  belongs_to :relation, :class_name => 'Person', :foreign_key => :person_b#, :conditions => {:voided => 0}
  belongs_to :type, :class_name => "RelationshipType", :foreign_key => :relationship # no default scope, should have retired
  #named_scope :guardian, :conditions => 'relationship_type.b_is_to_a = "Guardian"', :include => :type

end
