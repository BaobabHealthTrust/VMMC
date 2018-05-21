class Observation < ActiveRecord::Base
  self.table_name = "obs"
  self.primary_key = "obs_id"


  include Openmrs
  before_create :before_create
  before_save :before_save
  
  belongs_to :encounter, -> { where voided: 0 }
  belongs_to :order, -> { where voided: 0 }
  belongs_to :concept, -> { where retired: 0 }
  belongs_to :concept_name
  belongs_to :answer_concept, -> { where retired: 0 },  class_name: "Concept", foreign_key: "value_coded"
  belongs_to :answer_concept_name, -> { where voided: 0 }, class_name: "ConceptName", foreign_key: "value_coded_name_id"
  has_many :concept_names, through: "concept"

  #attr_accessible :value_text, :value_modifier, :concept_id, :person_id, :obs_datetime, :encounter_id, :location_id, :creator, :date_created, :uuid

  #named_scope :recent, lambda {|number| {:joins => [:encounter], :order => 'obs_datetime DESC,date_created DESC', :limit => number}}
  #named_scope :before, lambda {|date| {:conditions => ["obs_datetime < ? ", date], :order => 'obs_datetime DESC, date_created DESC', :limit => 1}}
  #named_scope :old, lambda {|number| {:order => 'obs_datetime ASC, date_created ASC', :limit => number}}
  #named_scope :question, lambda {|concept|
  #concept_id = concept.to_i
  # concept_id = ConceptName.first(:conditions => {:name => concept}).concept_id rescue 0 if concept_id == 0
  #{:conditions => {:concept_id => concept_id}}
  #}

  #scope :find_lazy, -> (id) { where(id: id) }

  #scope :question, lambda {|concept|
  #concept_id = concept.to_i
  # concept_id = ConceptName.first(:conditions => {:name => concept}).concept_id rescue 0 if concept_id == 0
  #{:conditions => {:concept_id => concept_id}}
  #}


  def before_save
    #self.changed_by = User.current.user_id unless User.current.blank?
    #self.date_changed = Time.now
    
  end

  def before_create
    self.location_id = Location.current_health_center.id
    self.creator = User.current.user_id unless User.current.blank?
    self.date_created = Time.now
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
  end

  def self.get_time_left(patient_id)
      res  = Observation.find_by_sql("SELECT obs.value_text AS time_left FROM obs WHERE (obs.concept_id ='9591' AND obs.person_id='#{patient_id}') AND obs.voided ='0'")
      return res[0]['time_left']
  end

  def patient_id=(patient_id)
    self.person_id=patient_id
  end

  def concept_name=(concept_name)
    self.concept_id = ConceptName.find_by_name(concept_name).concept_id
  rescue
    raise "\"#{concept_name}\" does not exist in the concept_name table"
  end

  def value_coded_or_text=(value_coded_or_text)
    return if value_coded_or_text.blank?

    value_coded_name = ConceptName.find_by_name(value_coded_or_text)
    if value_coded_name.nil?
      # TODO: this should not be done this way with a brittle hard ref to concept name
      #self.concept_name = "DIAGNOSIS, NON-CODED" if self.concept && self.concept.name && self.concept.fullname == "DIAGNOSIS"
      self.concept_name = "DIAGNOSIS, NON-CODED" if self.concept && self.concept.fullname == "DIAGNOSIS"
      self.value_text = value_coded_or_text
    else
      self.value_coded_name_id = value_coded_name.concept_name_id
      self.value_coded = value_coded_name.concept_id
      self.value_coded
    end
  end

  def to_s(tags=[])
    formatted_name = self.concept_name.typed(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.typed(tags).first.name || self.concept.fullname rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{formatted_name}:  #{self.answer_string(tags)}"
  end

  def name(tags=[])
    formatted_name = self.concept_name.tagged(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.tagged(tags).first.name rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{self.answer_string(tags)}"
  end

  def answer_string(tags=[])
    coded_answer_name = self.answer_concept.concept_names.typed(tags).first.name rescue nil
    coded_answer_name ||= self.answer_concept.concept_names.first.name rescue nil
    coded_name = "#{coded_answer_name} #{self.value_modifier}#{self.value_text} #{self.value_numeric}#{self.value_datetime.strftime("%d/%b/%Y") rescue nil}#{self.value_boolean && (self.value_boolean == true ? 'Yes' : 'No' rescue nil)}#{' ['+order.to_s+']' if order_id && tags.include?('order')}"
    #the following code is a hack
    #we need to find a better way because value_coded can also be a location - not only a concept
    return coded_name unless coded_name.blank?
    answer = Concept.find_by_concept_id(self.value_coded).shortname rescue nil

    if answer.nil?
      answer = Concept.find_by_concept_id(self.value_coded).fullname rescue nil
    end

    if answer.nil?
      answer = Concept.find_with_voided(self.value_coded).fullname rescue ""
      answer = answer + ' - retired'
    end

    return answer
  end

  def to_s_formatted
    text = "#{self.concept.fullname rescue 'Unknown concept name'}"
    text += ": #{self.answer_string}" if(self.answer_string.downcase != "yes" && self.answer_string.downcase != "unknown")
    text
  end
end
