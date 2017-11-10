class PersonAttribute < ActiveRecord::Base
  self.table_name = "person_attribute"
  self.primary_key = "person_attribute_id"

  before_create :before_create
  before_save :before_save


  include Openmrs
  
  belongs_to :type, -> { where retired: 0 }, :class_name => "PersonAttributeType", :foreign_key => :person_attribute_type_id
  belongs_to :person, -> { where voided: 0 }, :foreign_key => :person_id

  def before_save
    self.changed_by = User.current.user_id unless User.current.blank?
    self.date_changed = Time.now
  end

  def before_create
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end
  
end
