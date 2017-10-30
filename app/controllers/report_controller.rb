class ReportController < ApplicationController

def report
		@reports =  [
        ['/first_report','First Report'],
        ['/second_report','Second Report']
      ]
		render layout:false
end

	def first_report
		render layout: false
	end

	def second_report
		render layout:false
	end
end
