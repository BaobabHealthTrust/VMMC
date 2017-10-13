class PeopleController < ApplicationController

	def search
    @gender_options = [["", ""], ["Male", "M"], ["Female", "F"]]
		render layout: "form"
	end

	def search_results
    render layout: "menu"
	end

	def select
	end
  
end
