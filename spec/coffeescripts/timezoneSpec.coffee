define [
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/fr_FR'
  'vendor/timezone/pt_PT'
], (tz, detroit, french, portuguese)->
  module 'timezone',
    setup: ->
      @snapshot = tz.snapshot()

    teardown: ->
      tz.restore(@snapshot)

  moonwalk = new Date(Date.UTC(1969, 6, 21, 2, 56))

  test 'parse(valid datetime string)', ->
    equal +tz.parse(moonwalk.toISOString()), +moonwalk

  test 'parse(timestamp integer)', ->
    equal +tz.parse(+moonwalk), +moonwalk

  test 'parse(Date object)', ->
    equal +tz.parse(moonwalk), +moonwalk

  test 'parse(date array)', ->
    equal +tz.parse([1969, 7, 21, 2, 56]), +moonwalk

  test 'parse() should return null on failure', ->
    equal tz.parse('bogus'), null

  test 'parse() should return a date on success', ->
    equal typeof tz.parse(+moonwalk), 'object'

  test 'parse("") should fail', ->
    equal tz.parse(''), null

  test 'parse(null) should fail', ->
    equal tz.parse(null), null

  test 'parse() should parse relative to UTC by default', ->
    equal +tz.parse('1969-07-21 02:56'), +moonwalk

  test 'format() should format relative to UTC by default', ->
    equal tz.format(moonwalk, '%F %T%:z'), "1969-07-21 02:56:00+00:00"

  test 'format() should format in en_US by default', ->
    equal tz.format(moonwalk, '%c'), "Mon 21 Jul 1969 02:56:00 AM UTC"

  test 'format() should parse the value if necessary', ->
    equal tz.format('1969-07-21 02:56', '%F %T%:z'), "1969-07-21 02:56:00+00:00"

  test 'format() should return null if the parse fails', ->
    equal tz.format('bogus', '%F %T%:z'), null

  test 'format() should return null if the format string is unrecognized', ->
    equal tz.format(moonwalk, 'bogus'), null

  test "format() should preserve 12-hour+am/pm if the locale does define am/pm", ->
    time = tz.parse('1969-07-21 15:00:00')
    equal tz.format(time, '%-l%P'), "3pm"
    equal tz.format(time, '%I%P'), "03pm"
    equal tz.format(time, '%r'), "03:00:00 PM"

  test "format() should promote 12-hour+am/pm into 24-hour if the locale doesn't define am/pm", ->
    time = tz.parse('1969-07-21 15:00:00')
    tz.changeLocale(french, 'fr_FR')
    equal tz.format(time, '%-l%P'), "15"
    equal tz.format(time, '%I%P'), "15"
    equal tz.format(time, '%r'), "15:00:00"

  test 'shift() should adjust the date as appropriate', ->
    equal +tz.shift(moonwalk, '-1 day'), moonwalk - 86400000

  test 'shift() should apply multiple directives', ->
    equal +tz.shift(moonwalk, '-1 day', '-1 hour'), moonwalk - 86400000 - 3600000

  test 'shift() should parse the value if necessary', ->
    equal +tz.shift('1969-07-21 02:56', '-1 day'), moonwalk - 86400000

  test 'shift() should return null if the parse fails', ->
    equal tz.shift('bogus', '-1 day'), null

  test 'shift() should return null if the directives includes a format string', ->
    equal tz.shift('bogus', '-1 day', '%F %T%:z'), null

  test 'extendConfiguration() should curry the options into tz', ->
    tz.extendConfiguration(detroit, 'America/Detroit')
    equal +tz.parse('1969-07-20 21:56'), +moonwalk
    equal tz.format(moonwalk, '%c'), "Sun 20 Jul 1969 09:56:00 PM EST"

  test 'snapshotting should let you restore tz to a previous un-curried state', ->
    snapshot = tz.snapshot()
    tz.extendConfiguration(detroit, 'America/Detroit')
    tz.restore(snapshot)
    equal +tz.parse('1969-07-21 02:56'), +moonwalk
    equal tz.format(moonwalk, '%c'), "Mon 21 Jul 1969 02:56:00 AM UTC"

  test 'changeZone(...) should synchronously curry in a loaded zone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal +tz.parse('1969-07-20 21:56'), +moonwalk
    equal tz.format(moonwalk, '%c'), "Sun 20 Jul 1969 09:56:00 PM EST"

  test 'changeZone(...) should asynchronously curry in a zone by name', ->
    expect(2)
    stop()
    tz.changeZone('America/Detroit').then ->
      start()
      equal +tz.parse('1969-07-20 21:56'), +moonwalk
      equal tz.format(moonwalk, '%c'), "Sun 20 Jul 1969 09:56:00 PM EST"

  test 'changeLocale(...) should synchronously curry in a loaded locale', ->
    tz.changeLocale(french, 'fr_FR')
    equal tz.format(moonwalk, '%c'), "lun. 21 juil. 1969 02:56:00 UTC"

  test 'changeLocale(...) should asynchronously curry in a locale by name', ->
    expect(1)
    stop()
    tz.changeLocale('fr_FR').then ->
      start()
      equal tz.format(moonwalk, '%c'), "lun. 21 juil. 1969 02:56:00 UTC"

  test 'changeZone(...) should synchronously curry if pre-loaded', ->
    tz.preload('America/Detroit', detroit)
    tz.changeZone('America/Detroit')
    equal tz.format(moonwalk, '%c'), "Sun 20 Jul 1969 09:56:00 PM EST"
