define [
  'vendor/timezone/Europe/London'
  'timezone'
  'compiled/util/coupleTimeFields'
  'compiled/widget/DatetimeField'
  'jquery'
  'helpers/fakeENV'
], (london, tz, coupleTimeFields, DatetimeField, $, fakeENV) ->

  # make sure this is on today date but without seconds/milliseconds, so we
  # don't get screwed by dates shifting and seconds truncated during
  # reinterpretation of field values, but also make sure it's the middle of the
  # day so timezones don't shift the actual date from under us either
  fixed = new Date()
  fixed.setHours(12)
  fixed.setMinutes(0)
  fixed.setSeconds(0)
  fixed.setMilliseconds(0)

  tomorrow = new Date(fixed)
  tomorrow.setDate(tomorrow.getDate() + 1)

  module 'initial coupling',
    setup: ->
      @$start = $('<input type="text">')
      @$end = $('<input type="text">')
      @start = new DatetimeField(@$start, timeOnly: true)
      @end = new DatetimeField(@$end, timeOnly: true)

  test 'updates start to be <= end', ->
    @start.setTime(new Date(+fixed + 3600000))
    @end.setTime(fixed)
    coupleTimeFields(@$start, @$end)
    equal +@start.datetime, +fixed

  test 'leaves start < end alone', ->
    earlier = new Date(+fixed - 3600000)
    @start.setTime(earlier)
    @end.setTime(fixed)
    coupleTimeFields(@$start, @$end)
    equal +@start.datetime, +earlier

  test 'leaves blank start alone', ->
    @start.setTime(null)
    @end.setTime(fixed)
    coupleTimeFields(@$start, @$end)
    equal @start.blank, true

  test 'leaves blank end alone', ->
    @start.setTime(fixed)
    @end.setTime(null)
    coupleTimeFields(@$start, @$end)
    equal @end.blank, true

  test 'leaves invalid start alone', ->
    @$start.val('invalid')
    @start.setFromValue()
    @end.setTime(fixed)
    coupleTimeFields(@$start, @$end)
    equal @$start.val(), 'invalid'
    equal @start.invalid, true

  test 'leaves invalid end alone', ->
    @start.setTime(fixed)
    @$end.val('invalid')
    @end.setFromValue()
    coupleTimeFields(@$start, @$end)
    equal @$end.val(), 'invalid'
    equal @end.invalid, true

  test 'interprets time as occurring on date', ->
    @$date= $('<input type="text">')
    @date = new DatetimeField(@$date, dateOnly: true)
    @date.setDate(tomorrow)
    @start.setTime(fixed)
    @end.setTime(fixed)
    coupleTimeFields(@$start, @$end, @$date)
    equal @start.datetime.getDate(), tomorrow.getDate()
    equal @end.datetime.getDate(), tomorrow.getDate()

  module 'post coupling',
    setup: ->
      @$start = $('<input type="text">')
      @$end = $('<input type="text">')
      @start = new DatetimeField(@$start, timeOnly: true)
      @end = new DatetimeField(@$end, timeOnly: true)
      coupleTimeFields(@$start, @$end)

  test 'changing end updates start to be <= end', ->
    @start.setTime(new Date(+fixed + 3600000))
    @end.setTime(fixed)
    @$end.trigger('blur')
    equal +@start.datetime, +fixed

  test 'changing start updates end to be >= start', ->
    @end.setTime(new Date(+fixed - 3600000))
    @start.setTime(fixed)
    @$start.trigger('blur')
    equal +@end.datetime, +fixed

  test 'leaves start < end alone', ->
    earlier = new Date(+fixed - 3600000)
    @start.setTime(earlier)
    @end.setTime(fixed)
    @$start.trigger('blur')
    equal +@start.datetime, +earlier
    equal +@end.datetime, +fixed

  test 'leaves blank start alone', ->
    @start.setTime(null)
    @end.setTime(fixed)
    @$end.trigger('blur')
    equal @start.blank, true

  test 'leaves blank end alone', ->
    @start.setTime(fixed)
    @end.setTime(null)
    @$start.trigger('blur')
    equal @end.blank, true

  test 'leaves invalid start alone', ->
    @$start.val('invalid')
    @start.setFromValue()
    @end.setTime(fixed)
    @$end.trigger('blur')
    equal @$start.val(), 'invalid'
    equal @start.invalid, true

  test 'leaves invalid end alone', ->
    @start.setTime(fixed)
    @$end.val('invalid')
    @end.setFromValue()
    @$start.trigger('blur')
    equal @$end.val(), 'invalid'
    equal @end.invalid, true

  test 'does not rewrite blurred input', ->
    @$start.val('7') # interpreted as 7pm, but should not be rewritten
    @start.setFromValue()
    @end.setTime(new Date(+@start.datetime + 3600000))
    @$start.trigger('blur')
    equal @$start.val(), '7'

  test 'does not rewrite other input', ->
    @$start.val('7') # interpreted as 7pm, but should not be rewritten
    @start.setFromValue()
    @end.setTime(new Date(+@start.datetime + 3600000))
    @$end.trigger('blur')
    equal @$start.val(), '7'

  test 'does not switch time fields if in order by user profile timezone, even if out of order in local timezone', ->
    snapshot = tz.snapshot()

    # set local timezone to UTC
    tz.changeZone(london, 'Europe/London')

    # set user profile timezone to EST (UTC-4)
    fakeENV.setup(TIMEZONE: 'America/Detroit')

    # 1am in profile timezone, or 9pm in local timezone
    @$start.val('1:00 AM')
    @start.setFromValue()

    # 5pm in profile timezone, or 1pm in local timezone
    @$end.val('5:00 PM')
    @end.setFromValue()

    # store current end datetime
    endTime = +@end.datetime

    @$start.trigger('blur')

    tz.restore(snapshot)
    fakeENV.teardown()

    # check that the end datetime has not been changed
    equal +@end.datetime, endTime

  module 'with date field',
    setup: ->
      @$start = $('<input type="text">')
      @$end = $('<input type="text">')
      @$date= $('<input type="text">')
      @start = new DatetimeField(@$start, timeOnly: true)
      @end = new DatetimeField(@$end, timeOnly: true)
      @date = new DatetimeField(@$date, dateOnly: true)
      coupleTimeFields(@$start, @$end, @$date)

  test 'interprets time as occurring on date', ->
    @date.setDate(tomorrow)
    @$date.trigger('blur')
    @start.setTime(fixed)
    @start.parseValue()
    @end.setTime(fixed)
    @end.parseValue()
    equal @start.datetime.getDate(), tomorrow.getDate()
    equal @end.datetime.getDate(), tomorrow.getDate()
