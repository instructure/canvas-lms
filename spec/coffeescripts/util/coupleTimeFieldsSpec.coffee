define [
  'compiled/util/coupleTimeFields'
  'compiled/widget/DatetimeField'
  'jquery'
], (coupleTimeFields, DatetimeField, $) ->

  # make sure this is on today date but without seconds/milliseconds, so we
  # don't get screwed by dates shifting and seconds truncated during
  # reinterpretation of field values, but also make sure it's the middle of the
  # day so timezones don't shift the actual date from under us either
  fixed = new Date()
  fixed.setHours(12)
  fixed.setMinutes(0)
  fixed.setSeconds(0)
  fixed.setMilliseconds(0)

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
