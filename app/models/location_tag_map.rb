require 'composite_primary_keys'
class LocationTagMap < ActiveRecord::Base
  self.table_name = "location_tag_map"
  self.primary_keys = :location_tag_id, :location_id

  include Openmrs
  
  belongs_to :location_tag
  belongs_to :location
end
