class Person < ActiveRecord::Base
  self.table_name = "person"
  self.primary_key = "person_id"

  before_create :before_create
  before_save :before_save

  include Openmrs
  
  has_one :patient, -> { where voided: 0 }, :foreign_key => :patient_id, :dependent => :destroy
  has_many :names, -> { where(voided: 0).order 'person_name.preferred DESC'}, :class_name => 'PersonName', :foreign_key => :person_id, :dependent => :destroy
  has_many :addresses,  -> { where(voided: 0).order 'person_address.preferred DESC' },  :class_name => 'PersonAddress', :foreign_key => :person_id, :dependent => :destroy
  has_many :relationships, -> { where(voided: 0)}, :class_name => 'Relationship', :foreign_key => :person_a
  has_many :person_attributes, -> { where(voided: 0)}, :class_name => 'PersonAttribute', :foreign_key => :person_id
  has_many :observations, -> { where(voided: 0)}, :class_name => 'Observation', :foreign_key => :person_id, :dependent => :destroy

  def before_create
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end

  def before_save
    self.changed_by = User.current.user_id unless User.current.blank?
    self.date_changed = Time.now
  end

end
