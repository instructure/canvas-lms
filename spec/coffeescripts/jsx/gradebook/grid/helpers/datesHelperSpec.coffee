define [
  'jsx/gradebook/grid/helpers/datesHelper'
  'underscore'
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/America/Juneau'
], (DatesHelper, _, tz, detroit, juneau) ->

  defaultAssignment = ->
    {
      title: "assignment",
      created_at: "2015-07-06T18:35:22Z",
      due_at: "2015-07-14T18:35:22Z",
      updated_at: "2015-07-07T18:35:22Z"
    }

  module 'DatesHelper#parseDates'

  test 'returns a new object with specified dates parsed', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isDate(assignment.due_at)
    notOk _.isDate(assignment.updated_at)

  test 'gracefully handles null values', ->
    assignment = defaultAssignment()
    assignment.due_at = null
    datesToParse = ['created_at', 'due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isNull(assignment.due_at)

  test 'gracefully handles undefined values', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'undefined_due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isUndefined(assignment.undefined_due_at)

  module 'DatesHelper#formatDatetimeForDisplay',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'formats the date for display, adjusted for the timezone', ->
    assignment = defaultAssignment()
    tz.changeZone(detroit, 'America/Detroit')
    formattedDate = DatesHelper.formatDatetimeForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015 at 2:35pm"

    tz.changeZone(juneau, 'America/Juneau')
    formattedDate = DatesHelper.formatDatetimeForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015 at 10:35am"

  module 'DatesHelper#formatDateForDisplay',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'formats the date for display, adjusted for the timezone, excluding the time', ->
    assignment = defaultAssignment()
    tz.changeZone(detroit, 'America/Detroit')
    formattedDate = DatesHelper.formatDateForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015"

    tz.changeZone(juneau, 'America/Juneau')
    formattedDate = DatesHelper.formatDateForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015"

  module 'DatesHelper#isMidnight',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'returns true if the time is midnight, adjusted for the timezone', ->
    date = "2015-07-14T04:00:00Z"
    tz.changeZone(detroit, 'America/Detroit')
    ok DatesHelper.isMidnight(date)

    tz.changeZone(juneau, 'America/Juneau')
    notOk DatesHelper.isMidnight(date)
