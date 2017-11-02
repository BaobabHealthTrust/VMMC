module PatientService
	require 'bean'
	#require 'json'
	#require 'rest_client'
  ############# new DDE API start###################################
  def self.dde_settings
    data = {}
    dde_ip = GlobalProperty.find_by_property('dde.address').property_value rescue "localhost"
    dde_port = GlobalProperty.find_by_property('dde.port').property_value rescue "3009"
    dde_username = GlobalProperty.find_by_property('dde.username').property_value rescue "admin"
    dde_password = GlobalProperty.find_by_property('dde.password').property_value rescue "admin"

    data["dde_ip"] = dde_ip
    data["dde_port"] = dde_port
    data["dde_username"] = dde_username
    data["dde_password"] = dde_password
    data["dde_address"] = "http://#{dde_ip}:#{dde_port}"

    return data
  end

  def self.initial_dde_authentication_token
    dde_address = "#{dde_settings["dde_address"]}/v1/authenticate"
    passed_params = {:username => "admin", :password => "admin"}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers)
    dde_token = JSON.parse(received_params)#["data"]["token"]
    return dde_token
  end

  def self.dde_authentication_token
    dde_address = "#{dde_settings["dde_address"]}/v1/authenticate"
    dde_username = dde_settings["dde_username"]
    dde_password = dde_settings["dde_password"]
    passed_params = {:username => dde_username, :password => dde_password}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers)
    dde_token = JSON.parse(received_params)#["data"]["token"]
    return dde_token
  end

  def self.add_dde_user(data)
    dde_address = "http://admin:admin@#{dde_settings["dde_ip"]}:#{dde_settings["dde_port"]}/v1/add_user"
    passed_params = {
      :username => data["username"],
      :password => data["password"],
      :application => "ART",
      :site_code => data["site_code"],
      :description => data["description"]
    }

    headers = {:content_type => "json" }
    received_params = RestClient.put(dde_address, passed_params.to_json, headers){|response, request, result|response}
    dde_token = JSON.parse(received_params)["data"]["token"]
    #return dde_token
  end

  def self.verify_dde_token_authenticity(dde_token)
    dde_address = "#{dde_settings["dde_address"]}/v1/authenticated/#{dde_token}"
    received_params = RestClient.get(dde_address) {|request, response, result| request}
    status = JSON.parse(received_params)["status"]
    return status
  end

  def self.search_dde_by_identifier(identifier, dde_token)
    dde_address = "#{dde_settings["dde_address"]}/v1/search_by_identifier/#{identifier}/#{dde_token}"
    received_params = RestClient.get(dde_address){|response, request, result|response}
    received_params = "{}" if received_params.blank?
    results = JSON.parse(received_params){|response, request, result|response}
    return results
  end

  def self.search_dde_by_name_and_gender(params, token)
    return [] if params[:given_name].blank?
    gender = {'M' => 'Male', 'F' => 'Female'}
    passed_params = {
      :given_name => params[:given_name],
      :family_name => params[:family_name],
      :gender => gender[params[:gender].upcase],
      :token => token
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/search_by_name_and_gender"
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers)
    results = JSON.parse(received_params)["data"]["hits"] rescue {}
    return results
  end

  def self.dde_advanced_search(params)
    passed_params = {
      :given_name => params[:given_name],
      :family_name => params[:family_name],
      :gender => params[:gender],
      :birthdate => params[:birthdate],
      :home_district => params[:home_district],
      :token => self.dde_authentication_token
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/search_by_name_and_gender"
    received_params = RestClient.post(dde_address, passed_params)
    results = JSON.parse(received_params)["data"]["hits"]
    return results
  end

  def self.void_dde_patient(identifier)
    dde_token = self.dde_authentication_token
    dde_address = "#{dde_settings["dde_address"]}/v1/void_patient/#{identifier}/#{dde_token}"
    received_params = RestClient.get(dde_address)
    status = JSON.parse(received_params)["status"]
    return status
  end

  def self.update_dde_patient(person, dde_token)
    passed_params = self.generate_dde_data_to_be_updated(person, dde_token)
    dde_address = "#{dde_settings["dde_address"]}/v1/update_patient"
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers)
    results = JSON.parse(received_params)
    return results
  end

  def self.add_dde_patient(params, dde_token)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_patient"
    gender = {'M' => 'Male', 'F' => 'Female'}
    person = Person.new
    birthdate = "#{params["person"]['birth_year']}-#{params["person"]['birth_month']}-#{params["person"]['birth_day']}"
    birthdate = birthdate.to_date.strftime("%Y-%m-%d") rescue birthdate

    if params["person"]["birth_year"] == "Unknown"
      self.set_birthdate_by_age(person, params["person"]['age_estimate'], Date.today)
    else
      self.set_birthdate(person, params["person"]["birth_year"], params["person"]["birth_month"], params["person"]["birth_day"])
    end

    unless params["person"]['birthdate_estimated'].blank?
      person.birthdate_estimated = params["person"]['birthdate_estimated'].to_i
    end

    passed_params = {
      "family_name" => params["person"]["names"]["family_name"],
      "given_name" => params["person"]["names"]["given_name"],
      "middle_name" => params["person"]["names"]["middle_name"],
      "gender" => gender[params["person"]["gender"]],
      "attributes" => {},
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => {},
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "current_residence" => params["person"]["addresses"]["city_village"],
      "current_village" => params["person"]["addresses"]["city_village"],
      "current_ta" => params["filter"]["t_a"],
      "current_district" => params["person"]["addresses"]["state_province"],

      "home_village" => params["person"]["addresses"]["neighborhood_cell"],
      "home_ta" => params["person"]["addresses"]["county_district"],
      "home_district" => params["person"]["addresses"]["address2"],
      "token" => dde_token
    }

    headers = {:content_type => "json" }
    received_params = RestClient.put(dde_address, passed_params.to_json, headers){|response, request, result|response}
    results = JSON.parse(received_params)
    return results
  end

  def self.add_dde_conflict_patient(dde_return_path, params, dde_token)
    dde_address = "#{dde_settings["dde_address"]}#{dde_return_path}"
    gender = {'M' => 'Male', 'F' => 'Female'}
    person = Person.new
    birthdate = "#{params["person"]['birth_year']}-#{params["person"]['birth_month']}-#{params["person"]['birth_day']}"
    birthdate = birthdate.to_date.strftime("%Y-%m-%d") rescue birthdate

    if params["person"]["birth_year"] == "Unknown"
      self.set_birthdate_by_age(person, params["person"]['age_estimate'], Date.today)
    else
      self.set_birthdate(person, params["person"]["birth_year"], params["person"]["birth_month"], params["person"]["birth_day"])
    end

    unless params["person"]['birthdate_estimated'].blank?
      person.birthdate_estimated = params["person"]['birthdate_estimated'].to_i
    end

    passed_params = {
      "family_name" => params["person"]["names"]["family_name"],
      "given_name" => params["person"]["names"]["given_name"],
      "middle_name" => params["person"]["names"]["middle_name"],
      "gender" => gender[params["person"]["gender"]],
      "attributes" => {},
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => {},
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "current_residence" => (params["person"]["addresses"]["city_village"] rescue 'Other'),
      "current_village" => (params["person"]["addresses"]["city_village"] rescue 'Other'),
      "current_ta" => (params["filter"]["t_a"] rescue 'N/A'),
      "current_district" => (params["person"]["addresses"]["state_province"] rescue 'Other'),

      "home_village" => (params["person"]["addresses"]["neighborhood_cell"] rescue 'Other'),
      "home_ta" => (params["person"]["addresses"]["county_district"] rescue 'Other'),
      "home_district" => (params["person"]["addresses"]["address2"] rescue 'Other'),
      "token" => dde_token
    }

    headers = {:content_type => "json" }
    received_params = RestClient.put(dde_address, passed_params.to_json, headers){|response, request, result|response}
    results = JSON.parse(received_params)
    return results
  end

  def self.create_local_patient_from_dde(data)
    address_map = self.dde_openmrs_address_map
    city_village = address_map["city_village"]
    state_province = address_map["state_province"]
    neighborhood_cell = address_map["neighborhood_cell"]
    county_district = address_map["county_district"]
    address1 = address_map["address1"]
    address2 = address_map["address2"]

    demographics = {
      "person" =>
        {
        "occupation" => (data['attributes']['occupation'] rescue nil) ,
        "cell_phone_number" => (data['attributes']['cell_phone_number'] rescue nil),
        "home_phone_number" => (data['attributes']['home_phone_number'] rescue nil),
        "identifiers" => {"National id" => data["npid"]},
        "addresses"=>{
          "address1"=>(data['addresses']["#{address1}"] rescue nil),
          "address2"=>(data['addresses']["#{address2}"] rescue nil),
          "city_village"=>(data['addresses']["#{city_village}"] rescue nil),
          "state_province"=>(data['addresses']["#{state_province}"] rescue nil),
          "neighborhood_cell"=>(data['addresses']["#{neighborhood_cell}"] rescue nil),
          "county_district"=>(data['addresses']["#{county_district}"] rescue nil)
        },

        "age_estimate" => data["birthdate_estimated"] ,
        "birth_month"=> data["birthdate"].to_date.month ,
        "patient" =>{"identifiers"=>
            {"National id"=> data["npid"] }
        },
        "gender" => data["gender"] ,
        "birth_day" => data["birthdate"].to_date.day ,
        "names"=>
          {
          "family_name2" => (data['names']['family_name2'] rescue nil),
          "family_name" => (data['names']['family_name'] rescue nil) ,
          "given_name" => (data['names']['given_name'] rescue nil)
        },
        "birth_year" => data["birthdate"].to_date.year }
    }

    person = PatientService.create_from_form(demographics["person"])
    return person
  end

  def self.generate_dde_demographics(data, dde_token)
    old_npid = data["person"]["patient"]["identifiers"]["National id"]
    gender = {'M' => 'Male', 'F' => 'Female'}
    cell_phone_number = data["person"]["attributes"]["cell_phone_number"]
    cell_phone_number = "Unknown" if cell_phone_number.blank?

    occupation = data["person"]["attributes"]["occupation"]
    occupation = "Unknown" if occupation.blank?

    middle_name = data["person"]["names"]["middle_name"]
    middle_name = "N/A" if middle_name.blank?
    identifiers = data["person"]["patient"]["identifiers"]

    person = Person.new
    if data["person"]["birth_year"] == "Unknown"
      self.set_birthdate_by_age(person, data["person"]['age_estimate'], Date.today)
    else
      self.set_birthdate(person, data["person"]["birth_year"], data["person"]["birth_month"], data["person"]["birth_day"])
    end

    unless data["person"]['birthdate_estimated'].blank?
      person.birthdate_estimated = data["person"]['birthdate_estimated'].to_i
    end

    home_ta = data["person"]["addresses"]["county_district"]
    home_ta = "Other" if home_ta.blank?

    home_district = data["person"]["addresses"]["address2"]
    home_district = "Other" if home_district.blank?

    demographics = {
      "family_name" => data["person"]["names"]["family_name"],
      "given_name" => data["person"]["names"]["given_name"],
      "middle_name" => middle_name,
      "gender" => gender[data["person"]["gender"]],
      "attributes" => {
        "occupation" => occupation,
        "cell_phone_number" => cell_phone_number
      },
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => identifiers,
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "current_residence" => data["person"]["addresses"]["city_village"],
      "current_village" => data["person"]["addresses"]["city_village"],
      "current_ta" => "N/A",
      "current_district" => data["person"]["addresses"]["state_province"],

      "home_village" => data["person"]["addresses"]["neighborhood_cell"],
      "home_ta" => home_ta,
      "home_district" => home_district,
      "token" => dde_token
    }.delete_if{|k, v|v.to_s.blank?}

    return demographics
  end

  def self.generate_dde_demographics_for_merge(data)
    data =  data["data"]["hits"][0]
    gender = {'M' => 'Male', 'F' => 'Female'}

    demographics = {
      "npid" => data["npid"],
      "family_name" => data["names"]["family_name"],
      "given_name" => data["names"]["given_name"],
      "middle_name" => data["names"]["middle_name"],
      "gender" => gender[data["gender"]],
      "attributes" => data["attributes"],
      "birthdate" => data["birthdate"].to_date.strftime("%Y-%m-%d"),
      "identifiers" => data["patient"]["identifiers"],
      "birthdate_estimated" => (data["birthdate_estimated"].to_i == 1),
      "current_residence" => data["addresses"]["current_residence"],
      "current_village" => data["addresses"]["current_village"],
      "current_ta" => data["addresses"]["current_ta"],
      "current_district" => data["addresses"]["current_district"],

      "home_village" => data["addresses"]["home_village"],
      "home_ta" => data["addresses"]["home_ta"],
      "home_district" => data["addresses"]["home_district"]
    }

    return demographics
  end

  def self.generate_dde_data_to_be_updated(person, dde_token)
    data = PatientService.demographics(person)
    gender = {'M' => 'Male', 'F' => 'Female'}

    #occupation = data["person"]["attributes"]["occupation"]
    #occupation = "Unknown" if occupation.blank?

    middle_name = data["person"]["names"]["middle_name"]
    middle_name = "N/A" if middle_name.blank?

    npid = data["person"]["patient"]["identifiers"]["National id"]
    #old_npid = data["person"]["patient"]["identifiers"]["Old Identification Number"]
    #cell_phone_number = data["person"]["attributes"]["cell_phone_number"]
    #occupation = data["person"]["attributes"]["occupation"]
    #home_phone_number = data["person"]["attributes"]["home_phone_number"]
    #office_phone_number = data["person"]["attributes"]["office_phone_number"]

    #attributes = {}
    #attributes["cell_phone_number"] = cell_phone_number unless cell_phone_number.blank?
    #attributes["occupation"] = occupation unless occupation.blank?
    #attributes["home_phone_number"] = home_phone_number unless home_phone_number.blank?
    #attributes["office_phone_number"] = office_phone_number unless office_phone_number.blank?

    #identifiers = {}
    #identifiers["Old Identification Number"] = old_npid unless old_npid.blank?
    #identifiers["National id"] = old_npid unless npid.blank?

    identifiers =  self.patient_identifier_map(person)
    attributes =  self.person_attributes_map(person)

    home_ta = data["person"]["addresses"]["county_district"]
    home_ta = "Other" if home_ta.blank?

    home_district = data["person"]["addresses"]["address2"]
    home_district = "Other" if home_district.blank?
    
    demographics = {
      "npid" => npid,
      "family_name" => data["person"]["names"]["family_name"],
      "given_name" => data["person"]["names"]["given_name"],
      "middle_name" => middle_name,
      "gender" => gender[data["person"]["gender"]],
      "attributes" => attributes,
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => identifiers,
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "current_residence" => data["person"]["addresses"]["city_village"],
      "current_village" => data["person"]["addresses"]["city_village"],
      "current_ta" => "N/A",
      "current_district" => data["person"]["addresses"]["state_province"],

      "home_village" => data["person"]["addresses"]["neighborhood_cell"],
      "home_ta" => home_ta,
      "home_district" => home_district,
      "token" => dde_token
    }.delete_if{|k, v|v.to_s.blank?}

    return demographics
  end

  def self.add_dde_patient_after_search_by_identifier(data)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_patient"
    headers = {:content_type => "json" }
    received_params = RestClient.put(dde_address, data.to_json, headers){|response, request, result|response}
    results = JSON.parse(received_params)
    return results
  end

  def self.add_dde_patient_after_search_by_name(data)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_patient"
    headers = {:content_type => "json" }
    received_params = RestClient.put(dde_address, data.to_json, headers){|response, request, result|response}
    results = JSON.parse(received_params)
    return results
  end

  def self.merge_dde_patients(primary_pt_demographics, secondary_pt_demographics, dde_token)
    data = {
      "primary_record" => primary_pt_demographics,
      "secondary_record" => secondary_pt_demographics,
      "token" => dde_token
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/merge_records"
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, data.to_json, headers)
    results = JSON.parse(received_params)
    return results
  end

  def self.assign_new_dde_npid(person, old_npid, new_npid)
    national_patient_identifier_type_id = PatientIdentifierType.find_by_name("National id").patient_identifier_type_id
    old_patient_identifier_type_id = PatientIdentifierType.find_by_name("Old Identification Number").patient_identifier_type_id

    patient_national_identifier = person.patient.patient_identifiers.find(:last, :conditions => ["identifier_type =?",
        national_patient_identifier_type_id])

    ActiveRecord::Base.transaction do
      new_old_identification_identifier = person.patient.patient_identifiers.new
      new_old_identification_identifier.identifier_type = old_patient_identifier_type_id
      new_old_identification_identifier.identifier = old_npid
      new_old_identification_identifier.save

      new_national_identification_identifier = person.patient.patient_identifiers.new
      new_national_identification_identifier.identifier_type = national_patient_identifier_type_id
      new_national_identification_identifier.identifier = new_npid
      new_national_identification_identifier.save

      patient_national_identifier.void
    end

    return new_npid
  end

  def self.dde_openmrs_address_map
    data = { 
      "city_village" => "current_residence",
      "state_province" => "current_district",
      "neighborhood_cell" => "home_village",
      "county_district" => "home_ta",
      "address2" => "home_district",
      "address1" => "current_residence"
    }
    return data
  end

  def self.patient_identifier_map(person)
    identifier_map = {}
    patient_identifiers = person.patient.patient_identifiers
    patient_identifiers.each do |pt|
      key = pt.type.name
      value = pt.identifier
      next if value.blank?
      identifier_map[key] = value
    end
    return identifier_map
  end

  def self.person_attributes_map(person)
    attributes_map = {}
    person_attributes = person.person_attributes
    person_attributes.each do |pa|
      key = pa.type.name.downcase.gsub(/\s/,'_') #From Home Phone Number to home_phone_number
      value = pa.value
      next if value.blank?
      attributes_map[key] = value
    end
    return attributes_map
  end

  def self.get_remote_dde_person(data)
    patient = PatientBean.new('')
    patient.person_id = data["_id"]
    patient.patient_id = 0
    patient.address = data["addresses"]["current_residence"]
    patient.national_id = data["npid"]
    patient.name = data["names"]["given_name"] + ' ' + data["names"]["family_name"]
    patient.first_name = data["names"]["given_name"]
    patient.last_name = data["names"]["family_name"]
    patient.sex = data["gender"]
    patient.birthdate = data["birthdate"].to_date
    patient.birthdate_estimated =  data["age_estimate"].to_i
    date_created =  data["created_at"].to_date rescue Date.today
    patient.age = self.cul_age(patient.birthdate , patient.birthdate_estimated , date_created, Date.today)
    patient.birth_date = self.get_birthdate_formatted(patient.birthdate,patient.birthdate_estimated)
    patient.home_district = data["addresses"]["home_district"]
    patient.current_district = data["addresses"]["current_district"]
    patient.traditional_authority = data["addresses"]["home_ta"]
    patient.current_residence = data["addresses"]["current_residence"]
    patient.landmark = ""
    patient.home_village = data["addresses"]["home_village"]
    patient.occupation = data["attributes"]["occupation"]
    patient.cell_phone_number = data["attributes"]["cell_phone_number"]
    patient.home_phone_number = data["attributes"]["home_phone_number"]
    patient.old_identification_number = data["patient"]["identifiers"]["National id"]
    patient
  end

  def self.update_local_demographics_from_dde(person, data)
    names = data["names"]
    #identifiers = data["patient"]["identifiers"] rescue {}
    addresses = data["addresses"]
    attributes = data["attributes"]
    birthdate = data["birthdate"]
    birthdate_estimated = data["birthdate_estimated"]
    gender = data["gender"]
    
    person_name = person.names[0]
    person_address = person.addresses[0]


    city_village = addresses["current_residence"] rescue nil
    state_province = addresses["current_district"] rescue nil
    neighborhood_cell = addresses["home_village"] rescue nil
    county_district = addresses["home_ta"] rescue nil
    address2 = addresses["home_district"] rescue nil
    address1 = addresses["current_residence"] rescue nil

    #person.gender = gender
    #person.birthdate = birthdate.to_date
    #person.birthdate_estimated = birthdate_estimated
    #person.save

    person.update_attributes({
        :gender => gender,
        :birthdate => birthdate.to_date,
        :birthdate_estimated => birthdate_estimated
      })

    person_name.given_name = names["given_name"]
    person_name.middle_name = names["middle_name"]
    person_name.family_name = names["family_name"]
    person_name.save

    person_address.address1 = address1
    person_address.address2 = address2
    person_address.city_village = city_village
    person_address.county_district = county_district
    person_address.state_province = state_province
    person_address.neighborhood_cell = neighborhood_cell
    person_address.save

    (attributes || {}).each do |key, value|
      person_attribute_type = PersonAttributeType.find_by_name(key)
      next if person_attribute_type.blank?
      person_attribute_type_id = person_attribute_type.id
      person_attrib = person.person_attributes.find_by_person_attribute_type_id(person_attribute_type_id)

      if person_attrib.blank?
        person_attrib = PersonAttribute.new
        person_attrib.person_id = person.person_id
        person_attrib.person_attribute_type_id = person_attribute_type_id
      end

      person_attrib.value = value
      person_attrib.save
    end
=begin
    #Leave this part commented out please!!. Do not update identifiers locally from DDE.
   #New patient object was being created as a side effect when side National id was being updated
    (identifiers || {}).each do |key, value|
      patient_identifier_type = PatientIdentifierType.find_by_name(key)
      next if patient_identifier_type.blank?
      patient_identifier_type_id = patient_identifier_type.id
      patient_ident = person.patient.patient_identifiers.find_by_identifier_type(patient_identifier_type_id)

      if patient_ident.blank?
        patient_ident = PatientIdentifier.new
        patient_ident.patient_id = person.person_id
        patient_ident.identifier_type = patient_identifier_type_id
      end

      patient_ident.identifier = value
      patient_ident.save
    end
=end
  end
  
  ############# new DDE API END###################################

  def self.cul_age(birthdate , birthdate_estimated , date_created = Date.today, today = Date.today)

    # This code which better accounts for leap years
    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date = birthdate
    estimate = birthdate_estimated == 1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && date_created.year == today.year) ? 1 : 0
  end

  def self.get_birthdate_formatted(birthdate,birthdate_estimated)
    if birthdate_estimated == 1
      if birthdate.day == 1 and birthdate.month == 7
        birthdate.strftime("??/???/%Y")
      elsif birthdate.day == 15
        birthdate.strftime("??/%b/%Y")
      elsif birthdate.day == 1 and birthdate.month == 1
        birthdate.strftime("??/???/%Y")
      else
	      birthdate.strftime("%d/%b/%Y") unless birthdate.blank?
      end
    else
      birthdate.strftime("%d/%b/%Y")
    end
  end
  #............................................................. new code

  def self.remote_demographics(person_obj)
    demo = demographics(person_obj)

    demographics = {
      "person" =>
        {"attributes" => {
          "occupation" => demo['person']['attributes']['occupation'],
          "cell_phone_number" => demo['person']['attributes']['cell_phone_number'] || nil,
          "home_phone_number" => demo['person']['attributes']['home_phone_number'] || nil,
          "office_phone_number" => demo['person']['attributes']['office_phone_number'] || nil
        } ,

        "addresses"=>{"address1"=>demo['person']['addresses']['address1'],
          "address2"=>demo['person']['addresses']['address2'],
          "city_village"=>demo['person']['addresses']['city_village'],
          "state_province"=>demo['person']['addresses']['state_province'],
          "neighborhood_cell"=>demo['person']['addresses']['neighborhood_cell'],
          "county_district"=>demo['person']['addresses']['county_district']},

        "age_estimate" => person_obj.birthdate_estimated ,
        "birth_month"=> person_obj.birthdate.month ,
        "patient" =>{"identifiers"=>
            {"National id"=> demo['person']['patient']['identifiers']['National id'] }
        },
        "gender" => person_obj.gender.first ,
        "birth_day" => person_obj.birthdate.day ,
        "date_changed" => demo['person']['date_changed'] ,
        "names"=>
          {
          "family_name2" => demo['person']['names']['family_name2'],
          "family_name" => demo['person']['names']['family_name'] ,
          "given_name" => demo['person']['names']['given_name']
        },
        "birth_year" => person_obj.birthdate.year }
    }
  end

  def self.demographics(person_obj)

    if person_obj.birthdate_estimated==1
      birth_day = "Unknown"
      if person_obj.birthdate.month == 7 and person_obj.birthdate.day == 1
        birth_month = "Unknown"
      else
        birth_month = person_obj.birthdate.month
      end
    else
      birth_month = person_obj.birthdate.month rescue nil
      birth_day = person_obj.birthdate.day rescue nil
    end

    demographics = {"person" => {
        "date_changed" => person_obj.date_changed.to_s,
        "gender" => person_obj.gender,
				"birthdate" => person_obj.birthdate, 
        "birth_year" => person_obj.birthdate.year || nil,
        "birth_month" => birth_month,
        "birth_day" => birth_day,
        "names" => {
          "given_name" => person_obj.names.first.given_name,
          "middle_name" => person_obj.names.first.middle_name,
          "family_name" => person_obj.names.first.family_name,
          "family_name2" => person_obj.names.first.family_name2
        },
        "addresses"=>{"address1"=>(person_obj.addresses.first.address1 rescue ''),
          "address2"=>(person_obj.addresses.first.address2 rescue ''),
          "city_village"=>(person_obj.addresses.first.city_village rescue ''),
          "state_province"=>(person_obj.addresses.first.state_province rescue ''),
          "neighborhood_cell"=>(person_obj.addresses.first.neighborhood_cell rescue ''),
          "county_district"=>(person_obj.addresses.first.county_district rescue '')},

        "attributes" => {"occupation" => self.get_attribute(person_obj, 'Occupation'),
          "cell_phone_number" => self.get_attribute(person_obj, 'Cell Phone Number'),
					"home_phone_number" => self.get_attribute(person_obj, 'Home Phone Number'),
					"office_phone_number" => self.get_attribute(person_obj, 'Office Phone Number')}}}

    if not person_obj.patient.patient_identifiers.blank?
      demographics["person"]["patient"] = {"identifiers" => {}}
      person_obj.patient.patient_identifiers.each{|identifier|
        demographics["person"]["patient"]["identifiers"][identifier.type.name] = identifier.identifier
      }
    end

    return demographics
  end

  def self.phone_numbers(person_obj)
    phone_numbers = {}

    phone_numbers['Cell phone number'] = self.get_attribute(person_obj, 'Cell phone number') rescue nil
    phone_numbers['Office phone number'] = self.get_attribute(person_obj, 'Office phone number') rescue nil
    phone_numbers['Home phone number'] = self.get_attribute(person_obj, 'Home phone number') rescue nil

    phone_numbers
  end


  def self.patient_national_id_label(patient)
	  patient_bean = get_patient(patient.person)
    return unless patient_bean.national_id
    sex =  patient_bean.sex.match(/F/i) ? "(F)" : "(M)"

    address = patient_bean.current_district rescue ""
    if address.blank?
      address = patient_bean.current_residence rescue ""
    else
      address += ", " + patient_bean.current_residence unless patient_bean.current_residence.blank?
    end

    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,4,15,120,false,"#{patient_bean.national_id}")
    label.draw_multi_text("#{patient_bean.name.titleize}")
    label.draw_multi_text("#{patient_bean.national_id_with_dashes} #{patient_bean.birth_date}#{sex}")
    label.draw_multi_text("#{address}" ) unless address.blank?
    label.print(1)
  end


  def self.hiv_test_date(patient_id)
    test_date = Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?", patient_id, ConceptName.find_by_name("HIV test date").concept_id]).value_datetime rescue nil
    return test_date
  end

  def self.months_since_last_hiv_test(patient_id)
    #this can be done better
    session_date = Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?", patient_id, ConceptName.find_by_name("HIV test date").concept_id]).obs_datetime rescue Date.today

    today =  session_date
    hiv_test_date = self.hiv_test_date(patient_id)
    months = (today.year * 12 + today.month) - (hiv_test_date.year * 12 + hiv_test_date.month) rescue nil
    return months
  end

  def self.patient_hiv_status(patient)
    status = Concept.find(Observation.find(:first,
        :order => "obs_datetime DESC,date_created DESC",
        :conditions => ["value_coded IS NOT NULL AND person_id = ? AND concept_id = ?", patient.id,
          ConceptName.find_by_name("HIV STATUS").concept_id]).value_coded).fullname rescue "UNKNOWN"

    if status.upcase == 'UNKNOWN'
      return patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') ? 'Positive' : status
    end
    return status
  end

 

  def self.patient_is_child?(patient)
    return self.get_patient_attribute_value(patient, "age") <= 14 unless self.get_patient_attribute_value(patient, "age").nil?
    return false
  end

  def self.get_patient_attribute_value(patient, attribute_name, session_date = Date.today)

    patient_bean = get_patient(patient.person)
    if patient_bean.sex.upcase == 'MALE'
   		sex = 'M'
    elsif patient_bean.sex.upcase == 'FEMALE'
   		sex = 'F'
    end

    case attribute_name.upcase
    when "AGE"
      return patient_bean.age
    when "RESIDENCE"
      return patient_bean.address
    when "CURRENT_HEIGHT"
      obs = patient.person.observations.before((session_date + 1.days).to_date).question("HEIGHT (CM)").all
      return obs.first.answer_string.to_f rescue 0
    when "CURRENT_WEIGHT"
      obs = patient.person.observations.before((session_date + 1.days).to_date).question("WEIGHT (KG)").all
      return obs.first.answer_string.to_f rescue 0
    when "INITIAL_WEIGHT"
      obs = patient.person.observations.old(1).question("WEIGHT (KG)").all
      return obs.last.answer_string.to_f rescue 0
    when "INITIAL_HEIGHT"
      obs = patient.person.observations.old(1).question("HEIGHT (CM)").all
      return obs.last.answer_string.to_f rescue 0
    when "INITIAL_BMI"
      obs = patient.person.observations.old(1).question("BMI").all
      return obs.last.answer_string.to_f rescue nil
    when "MIN_WEIGHT"
      return WeightHeight.min_weight(sex, patient_bean.age_in_months).to_f
    when "MAX_WEIGHT"
      return WeightHeight.max_weight(sex, patient_bean.age_in_months).to_f
    when "MIN_HEIGHT"
      return WeightHeight.min_height(sex, patient_bean.age_in_months).to_f
    when "MAX_HEIGHT"
      return WeightHeight.max_height(sex, patient_bean.age_in_months).to_f
    end

  end



  def self.get_patient_identifier(patient, identifier_type)
    patient_identifier_type_id = PatientIdentifierType.find_by_name(identifier_type).patient_identifier_type_id rescue nil
    patient_identifier = PatientIdentifier.find(:first, :select => "identifier",
      :conditions  =>["patient_id = ? and identifier_type = ?", patient.id, patient_identifier_type_id],
      :order => "date_created DESC" ).identifier rescue nil
    return patient_identifier
  end



  def self.get_patient(person, current_date = Date.today)
    patient = PatientBean.new('')
    patient.person_id = person.id
    patient.patient_id = person.patient.id
    patient.address = person.addresses.first.city_village rescue nil
    patient.national_id = get_patient_identifier(person.patient, 'National id')
	  patient.national_id_with_dashes = get_national_id_with_dashes(person.patient) rescue nil
    names = person.names rescue nil
    patient.name = names[names.length > 1 ? (names.length - 1) : 0].given_name + ' ' + names[names.length > 1 ? (names.length - 1) : 0].family_name rescue nil
		patient.first_name = names[names.length > 1 ? (names.length - 1) : 0].given_name rescue nil
		patient.last_name = names[names.length > 1 ? (names.length - 1) : 0].family_name rescue nil
    patient.sex = sex(person)
    if age(person, current_date).blank?
      patient.age = 0
    else
      patient.age = age(person, current_date)
    end
    patient.age_in_months = age_in_months(person, current_date)
    patient.birth_date = birthdate_formatted(person)
    patient.birthdate_estimated = person.birthdate_estimated
    patient.current_district = person.addresses.first.state_province rescue nil
    patient.home_district = person.addresses.first.address2 rescue nil
    patient.traditional_authority = person.addresses.first.county_district rescue nil
    patient.current_residence = person.addresses.first.city_village rescue nil
    patient.landmark = person.addresses.first.address1 rescue nil
    patient.home_village = person.addresses.first.neighborhood_cell rescue nil
    patient.filing_number = get_patient_identifier(person.patient, 'Filing Number')
    patient.occupation = get_attribute(person, 'Occupation')
    patient.cell_phone_number = get_attribute(person, 'Cell phone number')
    patient.office_phone_number = get_attribute(person, 'Office phone number')
    patient.home_phone_number = get_attribute(person, 'Home phone number')
    patient
  end

  def self.get_attribute(person, attribute)
    PersonAttribute.where(["voided = 0 AND person_attribute_type_id = ? AND person_id = ?",
        PersonAttributeType.find_by_name(attribute).id, person.id]).first.value rescue nil
  end

  def self.age(person, today = Date.today)
    return nil if person.birthdate.nil?

    # This code which better accounts for leap years
    patient_age = (today.year - person.birthdate.year) + ((today.month - person.birthdate.month) + ((today.day - person.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date=person.birthdate
    estimate=person.birthdate_estimated==1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && person.date_created.year == today.year) ? 1 : 0
  end

	def self.create_from_form(params)
    return nil if params.blank?
		address_params = params["addresses"]
		names_params = params["names"]
		patient_params = params["patient"]
		params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|relation|cell_phone_number|home_phone_number|office_phone_number|agrees_to_be_visited_for_TB_therapy|agrees_phone_text_for_TB_therapy/) }
		birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }
		person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate|occupation|identifiers/) }

		if person_params["gender"].to_s == "Female"
      person_params["gender"] = 'F'
		elsif person_params["gender"].to_s == "Male"
      person_params["gender"] = 'M'
		end

		person = Person.create(person_params)

		unless birthday_params.empty?
		  if birthday_params["birth_year"] == "Unknown"
        self.set_birthdate_by_age(person, birthday_params["age_estimate"], person.session_datetime || Date.today)
		  else
        self.set_birthdate(person, birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
		  end
		end

    unless person_params['birthdate_estimated'].blank?
      person.birthdate_estimated = person_params['birthdate_estimated'].to_i
    end

		person.save

		person.names.create(names_params)
		person.addresses.create(address_params) unless address_params.empty? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Occupation").person_attribute_type_id,
		  :value => params["occupation"]) unless params["occupation"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id,
		  :value => params["cell_phone_number"]) unless params["cell_phone_number"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id,
		  :value => params["office_phone_number"]) unless params["office_phone_number"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id,
		  :value => params["home_phone_number"]) unless params["home_phone_number"].blank? rescue nil

    # TODO handle the birthplace attribute

		if (!patient_params.nil?)
		  patient = person.create_patient
      params["identifiers"].each{|identifier_type_name, identifier|
        next if identifier.blank?
        identifier_type = PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
        patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
		  } if params["identifiers"]
=begin
		  patient_params["identifiers"].each{|identifier_type_name, identifier|
        next if identifier.blank?
        identifier_type = PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
        patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
		  } if patient_params["identifiers"]
=end
		  # This might actually be a national id, but currently we wouldn't know
		  #patient.patient_identifiers.create("identifier" => patient_params["identifier"], "identifier_type" => PatientIdentifierType.find_by_name("Unknown id")) unless params["identifier"].blank?
		end

		return person
	end


  # Get the any BMI-related alert for this patient
  def self.current_bmi_alert(patient_weight, patient_height)
    weight = patient_weight
    height = patient_height
    alert = nil
    unless weight == 0 || height == 0
      current_bmi = (weight/(height*height)*10000).round(1);
      if current_bmi <= 18.5 && current_bmi > 17.0
        alert = 'Low BMI: Eligible for counseling'
      elsif current_bmi <= 17.0
        alert = 'Low BMI: Eligible for therapeutic feeding'
      end
    end

    alert
  end

  def self.sex(person)
    value = nil
    if person.gender == "M"
      value = "Male"
    elsif person.gender == "F"
      value = "Female"
    end
    value
  end

  def self.person_search_by_identifier_and_name(params)
    people = []
    given_name = params[:name].squish.split(' ')[0]
    family_name = params[:name].squish.split(' ')[1] rescue ''
    identifier = params[:identifier]

    people = Person.find(:all, :limit => 15, :joins =>"INNER JOIN person_name USING(person_id)
     INNER JOIN patient_identifier i ON i.patient_id = person.person_id AND i.voided = 0", :conditions => [
        "identifier = ? AND \
     person_name.given_name LIKE (?) AND \
     person_name.family_name LIKE (?)",
        identifier,
        "%#{given_name}%",
        "%#{family_name}%"
      ],:limit => 10,:order => "birthdate DESC")

    if people.length < 15
      people_like = Person.find(:all, :limit => 15,
        :joins =>"INNER JOIN person_name_code ON person_name_code.person_name_id = person.person_id
      INNER JOIN patient_identifier i ON i.patient_id = person.person_id AND i.voided = 0",
        :conditions => ["identifier = ? AND \
     ((person_name_code.given_name_code LIKE ? AND \
     person_name_code.family_name_code LIKE ?))",
          identifier,
          (given_name || '').soundex,
          (family_name || '').soundex
        ], :order => "birthdate DESC")
      people = (people + people_like).uniq rescue people
    end

    return people.uniq[0..9] rescue people
  end

  def self.person_search(params)
    people = []
    people = search_by_identifier(params[:identifier]) if params[:identifier]

    return people unless people.blank? || people.size > 1

    gender = params[:gender]
    given_name = params[:given_name].squish unless params[:given_name].blank?
    family_name = params[:family_name].squish unless params[:family_name].blank?

    people = Person.find(:all, :limit => 15, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
        "gender = ? AND \
     person_name.given_name = ? AND \
     person_name.family_name = ?",
        gender,
        given_name,
        family_name
      ],:limit => 10,:order => "birthdate DESC") if people.blank?

    if people.length < 15
=begin
       matching_people = people.collect{| person |
       person.person_id
        #                  }

=end

      people_like = Person.find(:all, :limit => 15, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
          "gender = ? AND \
     ((person_name_code.given_name_code LIKE ? AND \
     person_name_code.family_name_code LIKE ?))",
          gender,
          (given_name || '').soundex,
          (family_name || '').soundex
        ], :order => "person_name.given_name ASC, person_name_code.family_name_code ASC,birthdate DESC")
      people = (people + people_like).uniq rescue people
    end
=begin
    raise "done"

people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
        "gender = ? AND \
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?)",
        params[:gender],
        params[:given_name],
        (params[:given_name] || '').soundex,
        params[:family_name],
        (params[:family_name] || '').soundex
      ]) if people.blank?

    raise "afta pulling"
=end
    return people.uniq[0..9] rescue people
  end

  def self.search_by_identifier(identifier)
    people = PatientIdentifier.where(["identifier =?", identifier]).map{|id|
      id.patient.person
    }
    return people
  end

  def self.set_birthdate_by_age(person, age, today = Date.today)
    person.birthdate = Date.new(today.year - age.to_i, 7, 1)
    person.birthdate_estimated = 1
  end

  def self.set_birthdate(person, year = nil, month = nil, day = nil)
    raise "No year passed for estimated birthdate" if year.nil?

    # Handle months by name or number (split this out to a date method)
    month_i = (month || 0).to_i
    month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

    if month_i == 0 || month == "Unknown"
      person.birthdate = Date.new(year.to_i,7,1)
      person.birthdate_estimated = 1
    elsif day.blank? || day == "Unknown" || day == 0
      person.birthdate = Date.new(year.to_i,month_i,15)
      person.birthdate_estimated = 1
    else
      person.birthdate = Date.new(year.to_i,month_i,day.to_i)
      person.birthdate_estimated = 0
    end
  end

  def self.birthdate_formatted(person)
    if person.birthdate_estimated==1
      if person.birthdate.nil?
				return '00/00/0000'
      else
		    if person.birthdate.day == 1 and person.birthdate.month == 7
		      person.birthdate.strftime("??/???/%Y")
		    elsif person.birthdate.day == 15
		      person.birthdate.strftime("??/%b/%Y")
		    elsif person.birthdate.day == 1 and person.birthdate.month == 1
		      person.birthdate.strftime("??/???/%Y")
		    else
		      person.birthdate.strftime("%d/%b/%Y") unless person.birthdate.blank? rescue " "
		    end
      end
    else
      if !person.birthdate.blank?
        person.birthdate.strftime("%d/%b/%Y")
      else
        return '00/00/0000'
      end
    end
  end

  def self.age_in_months(person, today = Date.today)
    if !person.birthdate.blank?
      years = (today.year - person.birthdate.year)
      months = (today.month - person.birthdate.month)
      (years * 12) + months
    else
      return 0
    end
  end


  def self.get_national_id(patient, force = true)
    id = patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => patient).identifier rescue nil
    id
  end

  def self.get_remote_national_id(patient)
    id = patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless id.blank?
    PatientIdentifierType.find_by_name("National id").next_identifier(:patient => patient).identifier rescue nil
  end

  def self.get_national_id_with_dashes(patient, force = true)
    id = self.get_national_id(patient, force)
    length = id.length
    case length
    when 13
      id[0..4] + "-" + id[5..8] + "-" + id[9..-1] rescue id
    when 9
      id[0..2] + "-" + id[3..6] + "-" + id[7..-1] rescue id
    when 6
      id[0..2] + "-" + id[3..-1] rescue id
    else
      id
    end
  end


  def self.occupations
    ['','Driver','Housewife','Messenger','Business','Farmer','Salesperson','Teacher',
      'Student','Security guard','Domestic worker', 'Police','Office worker',
      'Preschool child','Mechanic','Prisoner','Craftsman','Healthcare Worker','Soldier'].sort.concat(["Other","Unknown"])
  end


end
