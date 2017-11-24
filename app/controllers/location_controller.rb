class LocationController < ApplicationController
  def create
    clinic_name = params[:location_name]
    available_location = Location.find_by_name(clinic_name[:clinic_name])

    if available_location.blank?
      location = Location.new
      location.name = clinic_name[:clinic_name]
      location.creator  = User.current.id.to_s
      location.uuid = ""
      location.date_created  = Time.current.strftime("%Y-%m-%d %H:%M:%S")
      location.save #rescue (result = false)

      location_tag_map = LocationTagMap.new
      location_tag_map.location_id = location.id
      location_tag_map.location_tag_id = LocationTag.find_by_name("Workstation location").id
      result = location_tag_map.save #rescue (result = false)

      if result == true then
        flash[:notice] = "location #{clinic_name[:clinic_name]} added successfully"
      else
        flash[:notice] = "location #{clinic_name[:clinic_name]} addition failed"
      end
    else
      location_tag_map = LocationTagMap.new
      location_tag_map.location_id = Location.find_by_name(clinic_name[:clinic_name]).id
      location_tag_map.location_tag_id = LocationTag.find_by_name("Workstation location").id
      result = location_tag_map.save rescue (result = false)

      if result == true then
        flash[:notice] = "location #{clinic_name[:clinic_name]} added successfully"
      else
        flash[:notice] = "<span style='color:red; display:block; background-color:#DDDDDD;'>location #{clinic_name[:clinic_name]} addition failed</span>"
      end
    end

    redirect_to("/") and return
  end

  def search
    names = search_locations(params[:search_string].to_s, params[:act].to_s)
    render :text => "<li>" + names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def print
    location_name = params[:location_name][:clinic_name].to_s
    print_location_and_redirect("/location/location_label?location_name=#{location_name}", "/")
  end

  def delete
    clinic_name = params[:location_name]
    location_id = Location.find_by_name(clinic_name[:clinic_name]).id
    location_tag_id = LocationTag.find_by_name("Workstation location").id 
    location_tag_map = LocationTagMap.find([location_tag_id, location_id])
    location_tag_map.delete
    flash[:notice] = "location #{clinic_name[:clinic_name]} delete successfully"
    redirect_to "/" and return 
  end
  
  def search_locations(search_string, act)
    field_name = "name"
    if (act == "delete"  || act == "print")
      sql = "SELECT * FROM location WHERE location_id IN (SELECT location_id
             FROM location_tag_map WHERE location_tag_id = (SELECT location_tag_id
	           FROM location_tag WHERE name = 'Workstation Location')) ORDER BY name ASC"
    elsif act == "create"
      sql = "SELECT * FROM location WHERE location_id NOT IN (SELECT location_id
              FROM location_tag_map WHERE location_tag_id = (SELECT location_tag_id
	            FROM location_tag WHERE name = 'Workstation Location'))  AND name LIKE '%#{search_string}%'
              ORDER BY name ASC"
    end

    Location.find_by_sql(sql).collect{|name| name.send(field_name)}
  end

end
