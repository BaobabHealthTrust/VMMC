class PeopleController < ApplicationController

  def new
		@occupations = occupations
    render layout: "form"
	end

	def search
		render layout: "form"
	end

	def search_results
    @people = Person.limit(5)
    @patients = @people
    @relation = []
    render layout: "menu"
	end

  def search_by_identifier
    local_results = PatientService.search_by_identifier(params[:identifier])

    if local_results.blank?
      flash[:notice] = "No matching person found with number #{params[:identifier]}"
      redirect_to("/") and return
    end

    if local_results.length == 1
      found_person = local_results.first
      redirect_to("/patients/show/#{found_person.person_id}") and return
    end
    
    if local_results.length > 1
      redirect_to :action => 'duplicates' ,:search_params => params
      return
    end

  end

	def select
    person_id = params[:person][:id]
    if person_id == '0'
      redirect_to controller: 'people',
        action: 'new',
        gender: params[:gender],
        given_name: params[:given_name],
        family_name: params[:family_name],
        family_name2: params[:family_name2], 
        address2: params[:address2],
        identifier: params[:identifier],
        relation: params[:relation]
    end

    if person_id != '0'
      redirect_to("/patients/show/#{person_id}") and return
    end

	end

  def occupations
    ['','Driver','Housewife','Messenger','Business','Farmer','Salesperson','Teacher',
			'Student','Security guard','Domestic worker', 'Police','Office worker',
			'Preschool child','Mechanic','Prisoner','Craftsman','Healthcare Worker','Soldier'].sort.concat(["Other","Unknown"])
  end

  def region
    region_conditions = ["name LIKE (?)", "#{params[:value]}%"]
    regions = Region.where(region_conditions).order("region_id")

    regions = regions.map do |r|
      if r.name != "Foreign"
        "<li value=\"#{r.name}\">#{r.name}</li>"
      end
    end
    render :text => regions.join('')  and return
  end

  def district
    region_id = Region.find_by_name("#{params[:filter_value]}").id
    region_conditions = ["name LIKE (?) AND region_id = ? ", "#{params[:search_string]}%", region_id]
    districts = District.where(region_conditions).order("name")

    districts = districts.map do |d|
      "<li value=\"#{d.name}\">#{d.name}</li>"
    end
    render :text => districts.join('') + "<li value='Other'>Other</li>" and return
  end

  def traditional_authority
    district_id = District.find_by_name("#{params[:filter_value]}").id
    traditional_authority_conditions = ["name LIKE (?) AND district_id = ?", "%#{params[:search_string]}%", district_id]

    traditional_authorities = TraditionalAuthority.where(traditional_authority_conditions).order("name")
    traditional_authorities = traditional_authorities.map do |t_a|
      "<li value=\"#{t_a.name}\">#{t_a.name}</li>"
    end
    render :text => traditional_authorities.join('') + "<li value='Other'>Other</li>" and return
  end

  def village
    traditional_authority_id = TraditionalAuthority.find_by_name("#{params[:filter_value]}").id
    village_conditions = ["name LIKE (?) AND traditional_authority_id = ?", "%#{params[:search_string]}%", traditional_authority_id]
    
    villages = Village.where(village_conditions).order("name")
    villages = villages.map do |v|
      "<li value=\"" + v.name + "\">" + v.name + "</li>"
    end
    render :text => villages.join('') + "<li value='Other'>Other</li>" and return
  end

  # Landmark containing the string given in params[:value]
  def landmark
    landmarks = PersonAddress.where(["city_village = (?) AND address1 LIKE (?)", "#{params[:filter_value]}", "#{params[:search_string]}%"]).select("DISTINCT address1")

    landmarks = landmarks.map do |v|
      "<li value=\"#{v.address1}\">#{v.address1}</li>"
    end
    render :text => landmarks.join('') + "<li value='Other'>Other</li>" and return
  end

end
