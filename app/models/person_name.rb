class PersonName < ActiveRecord::Base
  self.table_name = "person_name"
  self.primary_key = "person_name_id"

  def self.search(field_name, search_string)
    search_results = self.where(["#{field_name} LIKE (?)","#{search_string}%"]).group("#{field_name}").limit(10)
    return search_results
  end
  
end
