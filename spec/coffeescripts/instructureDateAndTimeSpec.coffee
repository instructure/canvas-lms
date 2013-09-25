define [
  'jquery'
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/America/Juneau'
  'jquery.instructure_date_and_time'
], ($, tz, detroit, juneau) ->
  module 'parseFromISO',
    setup: ->
      @snapshot = tz.snapshot()

    teardown: ->
      tz.restore(@snapshot)

  expectedTimestamp = Date.UTC(2013, 8, 1) / 1000

  test 'should have valid: true on success', ->
    equal $.parseFromISO('2013-09-01T00:00:00Z').valid, true

  test 'should have valid: false on failure', ->
    equal $.parseFromISO(null).valid, false
    equal $.parseFromISO('bogus').valid, false

  test 'should validate year', ->
    equal $.parseFromISO('yyyy-01-01T00:00:00+0000').valid, false

  test 'should validate month', ->
    equal $.parseFromISO('2013-mm-01T00:00:00+0000').valid, false

  test 'should validate day', ->
    equal $.parseFromISO('2013-09-ddT00:00:00+00').valid, false

  test 'should validate hour', ->
    equal $.parseFromISO('2013-09-01Thh:00:00+00').valid, false

  test 'should validate minute', ->
    equal $.parseFromISO('2013-09-01T00:mm:00+00').valid, false

  test 'should validate second', ->
    equal $.parseFromISO('2013-09-01T00:00:ss+00').valid, false

  test 'should validate offset', ->
    equal $.parseFromISO('2013-09-01T00:00:00+zz').valid, false

  test 'should allow negative offsets', ->
    parsed = $.parseFromISO('2013-08-31T17:00:00-07')
    equal parsed.valid, true
    equal parsed.timestamp, expectedTimestamp

  test 'should allow positive offsets', ->
    parsed = $.parseFromISO('2013-09-01T03:00:00+03')
    equal parsed.valid, true
    equal parsed.timestamp, expectedTimestamp

  test 'should allow Z offset', ->
    parsed = $.parseFromISO('2013-09-01T00:00:00Z')
    equal parsed.valid, true
    equal parsed.timestamp, expectedTimestamp

  test 'should ignore milliseconds if present', ->
    parsed = $.parseFromISO('2013-09-01T00:00:00.123Z')
    equal parsed.valid, true
    equal parsed.timestamp, expectedTimestamp

  test 'should fudge the time object', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('2013-09-01T00:00:00Z')
    equal parsed.time.getHours(), 20 # -4 offset between UTC and EDT

  test 'should fudge the datetime object', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('2013-09-01T00:00:00Z')
    equal parsed.datetime.getHours(), 20 # -4 offset between UTC and EDT

  test 'should construct date_formatted in the profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('2013-09-02T02:00:00Z')
    equal parsed.date_formatted, 'Sep 1, 2013' # Sep 2nd at 2am UTC == Sep 1 at 10pm EDT

  test 'should construct time_formatted in the profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('2013-09-02T02:00:00Z')
    equal parsed.time_formatted, '10pm' # Sep 2nd at 2am UTC == Sep 1 at 10pm EDT

  test 'should construct datetime_formatted in the profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('2013-09-02T02:00:00Z')
    equal parsed.datetime_formatted, 'Sep 1, 2013 at 10pm' # Sep 2nd at 2am UTC == Sep 1 at 10pm EDT

  test 'should not fudge the timestamp', ->
    tz.changeZone(detroit, 'America/Detroit')
    parsed = $.parseFromISO('1970-01-01T00:00:00Z')
    equal parsed.timestamp, 0

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
