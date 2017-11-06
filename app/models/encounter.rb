class Encounter < ActiveRecord::Base
  self.table_name = "encounter"
  self.primary_key = "encounter_id"

  before_create :before_create
  before_save :before_save
  include Openmrs
  
  has_many :observations, :dependent => :destroy
  belongs_to :type,-> { where retired: 0 }, class_name: "EncounterType", foreign_key: "encounter_type"
  belongs_to :provider, -> { where voided: 0 }, class_name: "Person", foreign_key: "provider_id"
  belongs_to :patient, -> { where voided: 0 }

  def before_save
    self.provider = User.current.person if self.provider.blank?
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
    self.changed_by = User.current.user_id unless User.current.blank?
    self.date_changed = Time.now
  end

  def before_create
    self.location_id = Location.current_health_center.id
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end
  
end
