module CustomDateHelpers
  include TextHelper

  # Formatted output: Mmm d, e.g. 'Jan 1'
  def format_date_for_view(date, format = :short)
    I18n.l(date.to_date, format: format)
  end

  # Formatted output: Mmm d at h:mm, e.g. 'Jan 1 at 1:01pm'
  def format_time_for_view(time)
    datetime_string(time, :no_words).gsub(/ +/, ' ')
  end
end
