# requires $.parseFromISO and $.dateString
define ['i18n!dates'], (I18n) ->
  semanticDateRange = (startISO, endISO) ->
    unless startISO
      return """
        <span class="date-range date-range-no-date">
          #{I18n.t 'no_date', 'No Date'}
        </span>
      """

    startAt = $.parseFromISO startISO
    endAt = $.parseFromISO endISO
    startDay = startAt.date_formatted
    if startAt.timestamp != endAt.timestamp
      endDay = endAt.date_formatted
      # TODO: i18n
      if startDay != endDay
        """
        <span class="date-range">
          <time datetime='#{startAt.time.toISOString()}'>
            #{startDay} at #{startAt.time_formatted}
          </time> -
          <time datetime='#{endAt.time.toISOString()}'>
            #{endDay} at #{endAt.time_formatted}
          </time>
        </span>
        """
      else
        """
        <span class="date-range">
          <time datetime='#{startAt.time.toISOString()}'>
            #{startDay}, #{startAt.time_formatted}
          </time> -
          <time datetime='#{endAt.time.toISOString()}'>
            #{endAt.time_formatted}
          </time>
        </span>
        """
    else
      """
      <span class="date-range">
        <time datetime='#{startAt.time.toISOString()}'>
          #{startDay} at #{startAt.time_formatted}
        </time>
      </span>
      """
