define [
  'compiled/util/parseDatetime'
], (parseDatetime) ->

  module 'parsedatetime',
    setup: ->
      @datePortion = "Jul 20, 1969"
      @timePortion = "6:56pm"

  test 'works on date only strings', ->
    equal +parseDatetime(@datePortion), +new Date(1969, 6, 20)

  test 'works on time only strings', ->
    today = new Date()
    equal +parseDatetime(@timePortion), +new Date(today.getFullYear(), today.getMonth(), today.getDate(), 18, 56)

  test 'works on date+time strings (date.formats.full_with_weekday)', ->
    string = "#{@datePortion} #{@timePortion}"
    equal +parseDatetime(string), +new Date(1969, 6, 20, 18, 56)

  test 'works on date+time strings with " at " (time.event)', ->
    string = "#{@datePortion} at #{@timePortion}"
    equal +parseDatetime(string), +new Date(1969, 6, 20, 18, 56)

  test 'works on date+time strings with " by " (time.due_date)', ->
    string = "#{@datePortion} by #{@timePortion}"
    equal +parseDatetime(string), +new Date(1969, 6, 20, 18, 56)
