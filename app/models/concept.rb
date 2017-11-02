class Concept < ActiveRecord::Base
  self.table_name = "concept"
  self.primary_key = "concept_id"

  belongs_to :concept_class, -> { where retired: 0 }
  belongs_to :concept_datatype, -> { where retired: 0 }
  has_one :concept_numeric, :foreign_key => :concept_id, :dependent => :destroy
  #has_one :name, :class_name => 'ConceptName'
  has_many :answer_concept_names, -> { where voided: 0 }, :class_name => 'ConceptName'
  has_many :concept_names, -> { where voided: 0 }
  has_many :concept_maps # no default scope
  has_many :concept_sets  # no default scope
  has_many :concept_answers do # no default scope
    def limit(search_string)
      return self if search_string.blank?
      map{|concept_answer|
        concept_answer if concept_answer.name.match(search_string)
      }.compact
    end
  end
  
  has_many :drugs#, :conditions => {:retired => 0}
  has_many :concept_members, :class_name => 'ConceptSet', :foreign_key => :concept_set

  default_scope { where(retired: false) }
  def self.find_by_name(concept_name)
    #Concept.find(:first, :joins => 'INNER JOIN concept_name on concept_name.concept_id = concept.concept_id', :conditions => ["concept.retired = 0 AND concept_name.voided = 0 AND concept_name.name =?", "#{concept_name}"])
    Concept.joins("INNER JOIN concept_name ON concept_name.concept_id = concept.concept_id").where("concept_name.name = '#{concept_name}' AND concept_name.voided = 0").first
  end
  
end
