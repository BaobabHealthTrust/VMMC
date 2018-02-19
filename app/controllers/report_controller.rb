class ReportController < ApplicationController

  def report
		@reports =  [
      ['/registration_report_menu','Registration Report'],
      ['/quartely_report_menu','VMMC - District Quarterly Report']
    ]
		render layout:false
  end

  def registration_report_menu
    render layout: "full_page_form"
  end

  def registration_report
    render layout: "menu"
  end

  def quartely_report_menu
    render layout: "full_page_form"
  end

  def quartely_report
    @location_name = Location.current_health_center.name
    @reporting_year = Date.today.year
    @reporting_month = Date.today.strftime("%B")
  end
  
end
