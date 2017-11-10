class PersonAddress < ActiveRecord::Base
  self.table_name = "person_address"
  self.primary_key = "person_address_id"

  before_create :before_create
  
  include Openmrs
  belongs_to :person, :foreign_key => :person_id

  def before_create
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end

end
