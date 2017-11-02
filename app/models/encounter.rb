class Encounter < ActiveRecord::Base
  self.table_name = "encounter"
  self.primary_key = "encounter_id"

  has_many :observations, :dependent => :destroy
  belongs_to :type,-> { where retired: 0 }, class_name: "EncounterType", foreign_key: "encounter_type"
  belongs_to :provider, -> { where voided: 0 }, class_name: "Person", foreign_key: "provider_id"
  belongs_to :patient, -> { where voided: 0 }

end
