class PersonName < ActiveRecord::Base
  self.table_name = "person_name"
  self.primary_key = "person_name_id"

  before_create :before_create
  before_save :before_save
  
  include Openmrs
  def self.search(field_name, search_string)
    search_results = self.where(["#{field_name} LIKE (?)","#{search_string}%"]).group("#{field_name}").limit(10)
    return search_results
  end

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
