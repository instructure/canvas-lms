define [], () ->

  # create ISO date string with the number of days offset
  (daysOffset) ->
    daysOffset ||= 0
    d = new Date()
    d.setDate(d.getDate() + daysOffset)
    d.toISOString()
