class PeopleController < ApplicationController

	def search
    @gender_options = [["", ""], ["Male", "M"], ["Female", "F"]]
		render layout: "form"
	end
  
end
