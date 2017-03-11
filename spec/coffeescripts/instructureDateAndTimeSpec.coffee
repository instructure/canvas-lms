define [
  'jquery'
  'timezone'
  'timezone/America/Detroit'
  'timezone/America/Juneau'
  'timezone/pt_PT'
  'helpers/I18nStubber'
  'jquery.instructure_date_and_time'
], ($, tz, detroit, juneau, portuguese, I18nStubber) ->
  QUnit.module 'fudgeDateForProfileTimezone',
    setup: ->
      @snapshot = tz.snapshot()
      @original = new Date(expectedTimestamp = Date.UTC(2013, 8, 1))

    teardown: ->
      tz.restore(@snapshot)

  test 'should produce a date that formats via toString same as the original formats via tz', ->
    fudged = $.fudgeDateForProfileTimezone(@original)
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

  test 'should parse dates before the year 1000', ->
    # using specific string (and specific timezone to guarantee it) since tz.format has a bug pre-1000
    tz.changeZone(detroit, 'America Detroit')
    oldDate = new Date(Date.UTC(900, 1, 1, 0, 0, 0))
    oldFudgeDate = $.fudgeDateForProfileTimezone(oldDate)
    equal oldFudgeDate.toString('yyyy-MM-dd HH:mm:ss'), "0900-02-01 00:00:00"

  test 'should work on non-date date-like values', ->
    fudged = $.fudgeDateForProfileTimezone(+@original)
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

    fudged = $.fudgeDateForProfileTimezone(@original.toISOString())
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

  test 'should return null for invalid values', ->
    equal $.fudgeDateForProfileTimezone(null), null
    equal $.fudgeDateForProfileTimezone(''), null
    equal $.fudgeDateForProfileTimezone('bogus'), null

  test 'should not return treat 0 as invalid', ->
    equal +$.fudgeDateForProfileTimezone(0), +$.fudgeDateForProfileTimezone(new Date(0))

  test 'should be sensitive to profile time zone', ->
    tz.changeZone(detroit, 'America/Detroit')
    fudged = $.fudgeDateForProfileTimezone(@original)
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

    tz.changeZone(juneau, 'America/Juneau')
    fudged = $.fudgeDateForProfileTimezone(@original)
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

  QUnit.module 'unfudgeDateForProfileTimezone',
    setup: ->
      @snapshot = tz.snapshot()
      @original = new Date(expectedTimestamp = Date.UTC(2013, 8, 1))

    teardown: ->
      tz.restore(@snapshot)

  test 'should produce a date that formats via tz same as the original formats via toString()', ->
    unfudged = $.unfudgeDateForProfileTimezone(@original)
    equal tz.format(unfudged, '%F %T'), @original.toString('yyyy-MM-dd HH:mm:ss')

  test 'should work on non-date date-like values', ->
    unfudged = $.unfudgeDateForProfileTimezone(+@original)
    equal tz.format(unfudged, '%F %T'), @original.toString('yyyy-MM-dd HH:mm:ss')

    unfudged = $.unfudgeDateForProfileTimezone(@original.toISOString())
    equal tz.format(unfudged, '%F %T'), @original.toString('yyyy-MM-dd HH:mm:ss')

  test 'should return null for invalid values', ->
    equal $.unfudgeDateForProfileTimezone(null), null
    equal $.unfudgeDateForProfileTimezone(''), null
    equal $.unfudgeDateForProfileTimezone('bogus'), null

  test 'should not return treat 0 as invalid', ->
    equal +$.unfudgeDateForProfileTimezone(0), +$.unfudgeDateForProfileTimezone(new Date(0))

  test 'should be sensitive to profile time zone', ->
    tz.changeZone(detroit, 'America/Detroit')
    unfudged = $.unfudgeDateForProfileTimezone(@original)
    equal tz.format(unfudged, '%F %T'), @original.toString('yyyy-MM-dd HH:mm:ss')

    tz.changeZone(juneau, 'America/Juneau')
    unfudged = $.unfudgeDateForProfileTimezone(@original)
    equal tz.format(unfudged, '%F %T'), @original.toString('yyyy-MM-dd HH:mm:ss')

  QUnit.module 'sameYear',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should return true iff both dates from same year', ->
    date1 = new Date(0)
    date2 = new Date(+date1 + 86400000)
    date3 = new Date(+date1 - 86400000)
    ok $.sameYear(date1, date2)
    ok !$.sameYear(date1, date3)

  test 'should compare relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    date1 = new Date(5 * 3600000) # 5am UTC = 12am EST
    date2 = new Date(+date1 + 1000) # Dec 31, 1969 at 11:59:59pm EST
    date3 = new Date(+date1 - 1000) # Jan 1, 1970 at 00:00:01am EST
    ok $.sameYear(date1, date2)
    ok !$.sameYear(date1, date3)

  QUnit.module 'sameDate',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should return true iff both times from same day', ->
    date1 = new Date(86400000)
    date2 = new Date(+date1 + 3600000)
    date3 = new Date(+date1 - 3600000)
    ok $.sameDate(date1, date2)
    ok !$.sameDate(date1, date3)

  test 'should compare relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    date1 = new Date(86400000 + 5 * 3600000) # 5am UTC = 12am EST
    date2 = new Date(+date1 + 1000) # Jan 1, 1970 at 11:59:59pm EST
    date3 = new Date(+date1 - 1000) # Jan 2, 1970 at 00:00:01am EST
    ok $.sameDate(date1, date2)
    ok !$.sameDate(date1, date3)

  QUnit.module 'dateString',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'should format in profile timezone', ->
    I18nStubber.stub 'en', 'date.formats.medium': "%b %-d, %Y"
    tz.changeZone(detroit, 'America/Detroit')
    equal $.dateString(new Date(0)), 'Dec 31, 1969'

  QUnit.module 'timeString',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'should format in profile timezone', ->
    I18nStubber.stub 'en', 'time.formats.tiny': "%l:%M%P"
    tz.changeZone(detroit, 'America/Detroit')
    equal $.timeString(new Date(60000)), '7:01pm'

  test 'should format according to profile locale', ->
    I18nStubber.setLocale 'en-GB'
    I18nStubber.stub 'en-GB', 'time.formats.tiny': "%k:%M"
    equal $.timeString(new Date(46860000)), '13:01'

  test 'should use the tiny_on_the_hour format on the hour', ->
    I18nStubber.stub 'en', 'time.formats.tiny_on_the_hour': "%l%P"
    tz.changeZone(detroit, 'America/Detroit')
    equal $.timeString(new Date(0)), '7pm'

  QUnit.module 'datetimeString',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'should format in profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    I18nStubber.stub 'en',
      'date.formats.medium': "%b %-d, %Y"
      'time.formats.tiny': "%l:%M%P"
      'time.event': "%{date} at %{time}"
    equal $.datetimeString(new Date(60000)), 'Dec 31, 1969 at 7:01pm'

  test 'should translate into the profile locale', ->
    tz.changeLocale(portuguese, 'pt_PT', 'pt')
    I18nStubber.setLocale 'pt'
    I18nStubber.stub 'pt',
      'date.formats.medium': "%-d %b %Y"
      'time.formats.tiny': "%k:%M"
      'time.event': "%{date} em %{time}"
    equal $.datetimeString('1970-01-01 15:01:00Z'), "1 Jan 1970 em 15:01"

  QUnit.module '$.datepicker.parseDate',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'should accept localized strings and return them fudged', ->
    tz.changeZone(detroit, 'America/Detroit')
    tz.changeLocale(portuguese, 'pt_PT', 'pt')
    I18nStubber.setLocale 'pt'
    I18nStubber.stub 'pt',
      # this isn't the real format, but we want the %Y in here to make it
      # deterministic regardless of the year it's run in
      'date.formats.date_at_time': "%-d %b %Y em %k:%M"
    # 6pm EDT (detroit) = 22:00Z, but parsed will be fudged, so make sure to
    # also fudge what we're comparing to
    parsed = $.datepicker.parseDate('dd/mm/yyyy', "3 Ago 2015 em 18:06")
    fudged = $.fudgeDateForProfileTimezone('2015-08-03 22:06:00Z')
    equal +parsed, +fudged
