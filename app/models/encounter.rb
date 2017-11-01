class Encounter < ActiveRecord::Base
  self.table_name = "encounter"
  self.primary_key = "encounter_id"

  has_many :observations, :dependent => :destroy
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type#, :conditions => {:retired => 0}
  belongs_to :provider, :class_name => "Person", :foreign_key => :provider_id#, :conditions => {:voided => 0}
  belongs_to :patient#, :conditions => {:voided => 0}

end
