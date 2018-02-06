class ClinicController < ApplicationController

	def index
		@session_date =  session[:session_date].to_date rescue Date.today
    @user = User.find(session[:user]["user_id"])
	end

	def set_date
		@months = [["", ""]]
    1.upto(12){ |number|
      @months << [Date::MONTHNAMES[number], number.to_s]
    }

    day = Array.new(31){|d|d + 1 }
    @days = [""].concat day

    if request.post?
      session_date = params[:set_day] + "-" + params[:set_month] + "-" + params[:set_year]
      session[:session_date] = session_date.to_date
      redirect_to("/patients/show/#{params[:patient_id]}") and return unless params[:patient_id].blank?
      redirect_to("/") and return
    end

		render layout: "form"
	end

  def reset_date
    session.delete(:session_date)
    redirect_to("/patients/show/#{params[:patient_id]}") and return unless params[:patient_id].blank?
    redirect_to("/") and return
  end

	def overview
		render layout:false
	end

  def todays_statistics
    today = Date.today
    statistics = Location.statistics(today, today)
    render text: statistics.to_json
  end

  def this_months_statistics
    month_beginning = Date.today.beginning_of_month
    month_ending = Date.today.end_of_month
    statistics = Location.statistics(month_beginning, month_ending)
    render text: statistics.to_json
  end

  def this_years_statistics
    beginning_year = Date.today.beginning_of_year
    ending_of_year = Date.today.end_of_year
    statistics = Location.statistics(beginning_year, ending_of_year)
    render text: statistics.to_json
  end

  def todays_registration
    today = Date.today
    count = Location.total_registered(today, today)
    render text: count
  end

  def this_months_registration
    month_beginning = Date.today.beginning_of_month
    month_ending = Date.today.end_of_month
    count = Location.total_registered(month_beginning, month_ending)
    render text: count.to_json
  end

  def this_years_registration
    month_beginning = Date.today.beginning_of_month
    month_ending = Date.today.end_of_month
    count = Location.total_registered(month_beginning, month_ending)
    render text: count
  end

  def manage_locations
    @locations_options =  [
      ['/new_location','Add Location'],
      ['/delete_location','Delete Location'],
      ['/print_location','Print Location']
    ]
    render layout: false
  end

  def new_location
    render layout: "full_page_form"
  end

  def delete_location
    render layout: "full_page_form"
  end

  def print_location
    render layout: "full_page_form"
  end

  def work_station
    if request.post?
      location = Location.find(params[:location]) rescue nil
      location ||= Location.find_by_name(params[:location]) rescue nil

      valid_location = (generic_locations.include?(location.name)) rescue false

      unless location and valid_location
        flash[:error] = "Invalid workstation location"
        redirect_to("/work_station") and return
      end

      session[:workstation_location] = location.name
      redirect_to '/' and return
    end
    render layout: "full_page_form"
  end
  
end
