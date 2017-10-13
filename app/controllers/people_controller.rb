class PeopleController < ApplicationController

	def search
		render layout: "form"
	end

	def search_results
    render layout: "menu"
	end

	def select
	end
  
end
