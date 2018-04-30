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

    @start_date = "#{params["start_year"]}-#{params["start_month"]}-#{params["start_day"]}"
    @end_date = "#{params["end_year"]}-#{params["end_month"]}-#{params["end_day"]}"

  end

  def get_quartely_report_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    data = {}
    report = Report.new(start_date.to_date, end_date.to_date)
    age_category = report.age_category
    
    data["age"] = age_category
    render text: data.to_json and return
  end

  def get_hiv_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    hiv_art_status = report.hiv_art_status
    render text: hiv_art_status.to_json and return
  end

  def get_circumcision_status_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    circumcision_status = report.circumcision_status
    render text: circumcision_status.to_json and return
  end

  def get_contraindications_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    contraindications_identified = report.contraindications_identified
    render text: contraindications_identified.to_json and return
  end

  def get_consent_granted_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    consent_granted = report.consent_granted
    render text: consent_granted.to_json and return
  end
  
end
