# requires $.sameDate, $.dateString, $.timeString, $.datetimeString
define ['i18n!dates', 'jquery', 'timezone', 'str/htmlEscape', 'jquery.instructure_date_and_time'], (I18n, $, tz, htmlEscape) ->
  semanticDateRange = (startISO, endISO) ->
    unless startISO
      return """
        <span class="date-range date-range-no-date">
          #{htmlEscape I18n.t 'no_date', 'No Date'}
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
