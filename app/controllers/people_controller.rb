class PeopleController < ApplicationController

	def search
		render layout: "form"
	end

	def search_results
    @people = Person.limit(5)
    @patients = @people
    @relation = []
    render layout: "menu"
	end

	def select
	end
  
end
