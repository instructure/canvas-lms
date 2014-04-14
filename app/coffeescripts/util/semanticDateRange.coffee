# requires $.sameDate, $.dateString, $.timeString, $.datetimeString
define ['i18n!dates', 'jquery', 'timezone', 'jquery.instructure_date_and_time'], (I18n, $, tz) ->
  semanticDateRange = (startISO, endISO) ->
    unless startISO
      return """
        <span class="date-range date-range-no-date">
          #{I18n.t 'no_date', 'No Date'}
        </span>
      """

    startAt = tz.parse(startISO)
    endAt = tz.parse(endISO)
    if +startAt != +endAt
      if !$.sameDate(startAt, endAt)
        """
        <span class="date-range">
          <time datetime='#{startAt.toISOString()}'>
            #{$.datetimeString(startAt)}
          </time> -
          <time datetime='#{endAt.toISOString()}'>
            #{$.datetimeString(endAt)}
          </time>
        </span>
        """
      else
        """
        <span class="date-range">
          <time datetime='#{startAt.toISOString()}'>
            #{$.dateString(startAt)}, #{$.timeString(startAt)}
          </time> -
          <time datetime='#{endAt.toISOString()}'>
            #{$.timeString(endAt)}
          </time>
        </span>
        """
    else
      """
      <span class="date-range">
        <time datetime='#{startAt.toISOString()}'>
          #{$.datetimeString(startAt)}
        </time>
      </span>
      """
