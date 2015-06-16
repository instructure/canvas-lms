define ['compiled/util/secondsToTime'], (secondsToTime) ->

  module "secondsToTime"

  test "less than one minute", ->
    equal secondsToTime(0), "00:00"
    equal secondsToTime(1), "00:01"
    equal secondsToTime(11), "00:11"

  test "less than one hour", ->
    equal secondsToTime(61), "01:01"
    equal secondsToTime(900), "15:00"
    equal secondsToTime(3599), "59:59"

  test "less than 100 hours", ->
    equal secondsToTime(32400), "09:00:00"
    equal secondsToTime(359999), "99:59:59"

  test "more than 100 hours", ->
    equal secondsToTime(360000), "100:00:00"
    equal secondsToTime(478861), "133:01:01"
    equal secondsToTime(8000542), "2222:22:22"
