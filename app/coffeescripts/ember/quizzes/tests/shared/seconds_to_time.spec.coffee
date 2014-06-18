define ['../../shared/seconds_to_time'], (secondsToTime) ->

  module 'seconds_to_time'

  test 'pads durations with leading zeros', ->
    equal secondsToTime(42), '00:42'
    equal secondsToTime(63), '01:03'

  test 'includes hours in output', ->
    equal secondsToTime(3721), '01:02:01'
