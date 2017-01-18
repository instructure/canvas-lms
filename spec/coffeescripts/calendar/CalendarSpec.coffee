define [
  'compiled/calendar/Calendar'
  'compiled/util/fcUtil',
  'timezone'
  'vendor/timezone/America/Denver'
], (Calendar, fcUtil, tz, denver) ->

  module "Calendar",
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')

    teardown: ->
      tz.restore(@snapshot)

  test 'isSameWeek: should check boundaries in profile timezone', ->
    datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
    datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
    datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')

    ok !Calendar.prototype.isSameWeek(datetime1, datetime2)
    ok Calendar.prototype.isSameWeek(datetime2, datetime3)

  test 'isSameWeek: should behave with ambiguously timed/zoned arguments', ->
    datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
    datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
    datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')

    date1 = fcUtil.clone(datetime1).stripTime().stripZone()
    date2 = fcUtil.clone(datetime2).stripTime().stripZone()
    date3 = fcUtil.clone(datetime3).stripTime().stripZone()

    ok !Calendar.prototype.isSameWeek(date1, datetime2), 'sat-sun 1'
    ok !Calendar.prototype.isSameWeek(datetime1, date2), 'sat-sun 2'
    ok !Calendar.prototype.isSameWeek(date1, date2), 'sat-sun 3'

    ok Calendar.prototype.isSameWeek(date2, datetime3), 'sun-sat 1'
    ok Calendar.prototype.isSameWeek(datetime2, date3), 'sun-sat 2'
    ok Calendar.prototype.isSameWeek(date2, date3), 'sun-sat 3'
