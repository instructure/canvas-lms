module CustomDateHelpers
  include TextHelper

  # Formatted output: Mmm d, e.g. 'Jan 1'
  def format_date_for_view(date, format = nil)
    if format
      I18n.l(date.to_date, format: format)
    else
      date_string(date, :no_words)
    end
  end

  # Formatted output: Mmm d at h:mm, e.g. 'Jan 1 at 1:01pm'
  def format_time_for_view(time, date_format = nil)
    if date_format
      date = format_date_for_view(time.to_date, date_format)
      "#{date} at #{time_string(time)}"
    else
      datetime_string(time, :no_words).gsub(/ +/, ' ')
    end
  end
end
