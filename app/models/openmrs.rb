module Openmrs
=begin
  module ClassMethods
    def assign_scopes
      col_names = self.columns.map(&:name)
      self.default_scope {where "#{self.table_name}.voided = 0"} if col_names.include?("voided")
      self.default_scope {where "#{self.table_name}.retired = 0"} if col_names.include?("retired")
    end

    # We needed a way to break out of the default scope, so we introduce inactive
    def inactive(*args)
      col_names = self.columns.map(&:name)
      scope = {}
      scope = {:conditions => "#{self.table_name}.voided = 1"} if col_names.include?("voided")
      scope = {:conditions => "#{self.table_name}.retired = 1"} if col_names.include?("retired")
      with_scope({:find => scope}, :overwrite) do
        if ([:all, :first].include?(args.first))
          self.find(*args)
        else
          self.all(*args)
        end
      end
    end

    # Shortcut for  looking up OpenMRS models by name using symbols or name
    # e.g. Concept[:diagonis] instead of Concept.find_by_name('diagnosis')
    #      Location[:my_hospital] => Location.find_by_name('neno district hospital')
    def [](name)
      name = name.to_s.gsub('_', ' ')
      self.find_by_name(name)
    end

    # Include voided or retired records
    def find_with_voided(options)
      with_exclusive_scope { self.where(options)}
    end
  end


  def self.included(base)
    base.extend(ClassMethods)
    base.assign_scopes
  end
=end

  # Override this
  def after_void(reason = nil)
  end

  def void(reason = "Voided through VMMC",date_voided = Time.now, voided_by = (User.current.user_id unless User.current.nil?))
    unless voided?
      self.date_voided = date_voided
      self.voided = 1
      self.void_reason = reason
      self.voided_by = voided_by
      self.save
      self.after_void(reason)
    end
  end

  def voided?
    self.attributes.has_key?("voided") ? voided == 1 : raise("Model does not support voiding")
  end

  def add_location_obs
    obs = Observation.new()
    obs.person_id = self.patient_id
    obs.encounter_id = self.id
    obs.concept_id = ConceptName.find_by_name("WORKSTATION LOCATION").concept_id
    #obs.value_text = Location.current_location.name
    obs.obs_datetime = self.encounter_datetime
    obs.save
  end

end
