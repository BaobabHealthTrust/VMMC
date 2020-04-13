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

  def get_procedures_used_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    procedures_used = report.procedures_used
    render text: procedures_used.to_json and return
  end

  def get_adverse_events_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    intra_operation_adverse_events = report.intra_operation_adverse_events
    render text: intra_operation_adverse_events.to_json and return
  end

  def get_first_review_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    first_review = report.first_review
    render text: first_review.to_json and return
  end

  def get_first_review_adverse_events
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    first_review_adverse_events = report.first_review_adverse_events
    render text: first_review_adverse_events.to_json and return
  end

  def get_second_review_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    second_review = report.second_review
    render text: second_review.to_json and return
  end

  def get_second_review_adverse_events
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    second_review_adverse_events = report.second_review_adverse_events
    render text: second_review_adverse_events.to_json and return
  end

  def get_third_review_data
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    third_review_data = report.third_review
    render text: third_review_data.to_json and return
  end

  def get_third_review_adverse_events
    start_date = params[:start_date]
    end_date = params[:end_date]
    report = Report.new(start_date.to_date, end_date.to_date)
    third_review_adverse_events = report.third_review_adverse_events
    render text: third_review_adverse_events.to_json and return
  end

end
