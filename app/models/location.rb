class Location < ActiveRecord::Base
  self.table_name = "location"
  self.primary_key = "location_id"

  before_create :before_create
  
  def before_create
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end

  include Openmrs
  
  cattr_accessor :current_location

  def site_id
    Location.current_health_center.location_id.to_s
  rescue
    raise "The id for this location has not been set (#{Location.current_location.name}, #{Location.current_location.id})"
  end

  def children
    return [] if self.name.match(/ - /)
    Location.where(["name LIKE ?","%" + self.name + " - %"])
  end

  def parent
    return nil unless self.name.match(/(.*) - /)
    Location.find_by_name($1)
  end

  def site_name
    self.name.gsub(/ -.*/,"")
  end

  def related_locations_including_self
    if self.parent
      return self.parent.children + [self]
    else
      return self.children + [self]
    end
  end

  def related_to_location?(location)
    self.site_name == location.site_name
  end

  def self.current_health_center
    @@current_health_center ||= Location.find(GlobalProperty.find_by_property("current_health_center_id").property_value) rescue self.current_location
  end

  def self.statistics(start_date = Date.today, end_date = Date.today)
    encounter_names = ["VITALS", "CIRCUMCISION", "GENITAL EXAMINATION", "HIV TESTING",
      "MEDICAL HISTORY", "POST-OP REVIEW", "REGISTRATION"
    ]

    enounter_type_ids = EncounterType.where(["name IN (?)", encounter_names]).map(&:encounter_type_id)
    statistics = Encounter.where(["encounter_type IN (?) AND DATE(encounter_datetime) >= ? AND
         DATE(encounter_datetime) <= ?", enounter_type_ids, start_date.to_date, end_date.to_date]
    )
    data = {}
    statistics.each do |encounter|
      encounter_name = encounter.type.name.squish.upcase
      data[encounter_name] = 0 if data[encounter_name].blank?
      data[encounter_name] += 1
    end

    return data
  end

  def self.total_registered(start_date = Date.today, end_date = Date.today)
    encounter_names = ["REGISTRATION"]

    enounter_type_ids = EncounterType.where(["name IN (?)", encounter_names]).map(&:encounter_type_id)
    statistics = Encounter.where(["encounter_type IN (?) AND DATE(encounter_datetime) >= ? AND
         DATE(encounter_datetime) <= ?", enounter_type_ids, start_date.to_date, end_date.to_date]
    )
    return statistics.count
  end

end
