define ['compiled/util/semanticDateRange'], (semanticDateRange) ->

  module 'semanticDateRange'

  test 'different day', ->
    date1 = new Date(0)
    date2 = new Date(+date1 + 86400000)
    equal semanticDateRange(date1, date2),
      """
      <span class="date-range">
        <time datetime='1970-01-01T00:00:00.000Z'>
          Jan 1, 1970 at 12:00am
        </time> -
        <time datetime='1970-01-02T00:00:00.000Z'>
          Jan 2, 1970 at 12:00am
        </time>
      </span>
      """

  test 'same day, different time', ->
    date1 = new Date(0)
    date2 = new Date(+date1 + 3600000)
    equal semanticDateRange(date1, date2),
      """
      <span class="date-range">
        <time datetime='1970-01-01T00:00:00.000Z'>
          Jan 1, 1970, 12:00am
        </time> -
        <time datetime='1970-01-01T01:00:00.000Z'>
          1:00am
        </time>
      </span>
      """

  test 'same day, same time', ->
    date = new Date(0)
    equal semanticDateRange(date, date),
      """
      <span class="date-range">
        <time datetime='1970-01-01T00:00:00.000Z'>
          Jan 1, 1970 at 12:00am
        </time>
      </span>
      """

  test 'no date', ->
    equal semanticDateRange(null, null),
      """
      <span class="date-range date-range-no-date">
        No Date
      </span>
      """

  test 'can take ISO strings', ->
    date = (new Date(0)).toISOString()
    equal semanticDateRange(date, date),
      """
      <span class="date-range">
        <time datetime='1970-01-01T00:00:00.000Z'>
          Jan 1, 1970 at 12:00am
        </time>
      </span>
      """
