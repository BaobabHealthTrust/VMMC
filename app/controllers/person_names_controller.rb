class PersonNamesController < ApplicationController
def family_names
    search("family_name", params[:search_string])
  end

  def given_names
    search("given_name", params[:search_string])
  end

  def family_name2
    search("family_name2", params[:search_string])
  end

  def middle_name
    search("middle_name", params[:search_string])
  end

  def search(field_name, search_string)
    names = PersonName.search(field_name, search_string).collect{|person_name| person_name.send(field_name)}
    render text: "<li>" + names.map{|n| n } .join("</li><li>") + "</li>" and return
  end
  
end
