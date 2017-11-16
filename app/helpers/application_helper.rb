module ApplicationHelper
  def month_name_options(selected_months = [])
    i=0
    options_array = [[]] +Date::ABBR_MONTHNAMES[1..-1].collect{|month|[month,i+=1]} + [["Unknown","Unknown"]]
    options_for_select(options_array, selected_months)
  end

  def month_names
    months = [["", ""]]
    1.upto(12){ |number|
      months << [Date::MONTHNAMES[number], number.to_s]
    }
    return months
  end

  def days
    day = Array.new(31){|d|d + 1 }
    days = [""].concat day
    return days
  end

end
