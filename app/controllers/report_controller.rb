class ReportController < ApplicationController

  def report
		@reports =  [
      ['/registration_report_menu','Registration Report']
    ]
		render layout:false
  end

  def registration_report_menu
    render layout: "full_page_form"
  end

  def registration_report
    render layout: "menu"
  end
  
end
