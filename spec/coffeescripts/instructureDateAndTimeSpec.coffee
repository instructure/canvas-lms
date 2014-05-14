define [
  'jquery'
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/America/Juneau'
  'vendor/timezone/pt_PT'
  'i18nObj'
  'jquery.instructure_date_and_time'
], ($, tz, detroit, juneau, portuguese, I18n) ->
  module 'fudgeDateForProfileTimezone',
    setup: ->
      @snapshot = tz.snapshot()
      @original = new Date(expectedTimestamp = Date.UTC(2013, 8, 1))

    teardown: ->
      tz.restore(@snapshot)

  test 'should produce a date that formats via toString same as the original formats via tz', ->
    fudged = $.fudgeDateForProfileTimezone(@original)
    equal fudged.toString('yyyy-MM-dd HH:mm:ss'), tz.format(@original, '%F %T')

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

  module 'unfudgeDateForProfileTimezone',
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

  module 'sameYear',
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

  module 'sameDate',
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

  module 'midnight',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should return true iff the time is midnight', ->
    date1 = new Date(0)
    date2 = new Date(60000)
    ok $.midnight(date1)
    ok !$.midnight(date2)

  test 'should check time relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    date1 = new Date(0) # 12am UTC = 7pm EST
    date2 = new Date(5 * 3600000) # 5am UTC = 00:00am EST
    date3 = new Date(+date2 + 60000) # 00:01am EST
    ok !$.midnight(date1)
    ok $.midnight(date2)
    ok !$.midnight(date3)

  module 'dateString',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should format in profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal $.dateString(new Date(0)), 'Dec 31, 1969'

  module 'timeString',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should format in profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal $.timeString(new Date(0)), ' 7:00pm'

  module 'datetimeString',
    setup: ->
      @snapshot = tz.snapshot()
      @localeWas = I18n.locale
      @translationsWas = I18n.translations
      I18n.translations = {'pt': {'time': {'event': "%{date} em %{time}"}}}
    teardown: ->
      tz.restore(@snapshot)
      I18n.locale = @localeWas
      I18n.translations = @translationsWas

  test 'should format in profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal $.datetimeString(new Date(0)), 'Dec 31, 1969 at  7:00pm'

  test 'should translate into the profile locale', ->
    # this matches current behavior, but is incorrect behavior. having the
    # 12-hour 3:00 without a pm indicator doesn't allow it to be distinguished
    # from 3:00am. leaving it to be fixed in an upcoming patchset
    tz.changeLocale(portuguese, 'pt_PT')
    I18n.locale = 'pt'
    equal $.datetimeString('1970-01-01 15:00:00Z'), "Jan 1, 1970 em  3:00"

  # TODO: remove these second argument specs once the pickers know how to parse
  # localized datetimes
  test 'should not localize if second argument is false', ->
    tz.changeLocale(portuguese, 'pt_PT')
    I18n.locale = 'pt'
    equal $.datetimeString('1970-01-01 15:00:00Z', false), "Jan 1, 1970 at 3:00pm"

  test 'should still apply profile timezone when second argument is false', ->
    tz.changeZone(detroit, 'America/Detroit')
    tz.changeLocale(portuguese, 'pt_PT')
    I18n.locale = 'pt'
    equal $.datetimeString(new Date(0), false), 'Dec 31, 1969 at 7:00pm'
