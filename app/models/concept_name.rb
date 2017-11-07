class ConceptName < ActiveRecord::Base
  self.table_name = "concept_name"
  self.primary_key = "concept_name_id"

  include Openmrs
  
  has_many :concept_name_tag_maps # no default scope
  has_many :tags, :through => :concept_name_tag_maps, :class_name => 'ConceptNameTag'
  belongs_to :concept
  #named_scope :tagged, lambda{|tags| tags.blank? ? {} : {:include => :tags, :conditions => ['concept_name_tag.tag IN (?)', Array(tags)]}}
  #named_scope :typed, lambda{|tags| tags.blank? ? {} : {:conditions => ['concept_name_type IN (?)', Array(tags)]}}

  default_scope { where(voided: 0) }

  scope :tagged, ->(tags) {tags.blank? ? {} :  joins(:tags).where('concept_name_tag.tag IN (?)', Array(tags)) }
  scope :typed, ->(tags) {tags.blank? ? {} :  where('concept_name_type IN (?)', Array(tags)) }

end
