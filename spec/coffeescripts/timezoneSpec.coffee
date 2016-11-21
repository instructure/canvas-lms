define [
  'timezone'
  'i18nObj'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/fr_FR'
  'vendor/timezone/pt_PT'
  'vendor/timezone/zh_CN'
  'helpers/I18nStubber'
  'underscore'
  'translations/_core_en'
], (tz, i18nObj, detroit, french, portuguese, chinese, I18nStubber, _, trans)->

  module 'timezone',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  moonwalk = new Date(Date.UTC(1969, 6, 21, 2, 56))
  epoch = new Date(Date.UTC(1970, 0, 1, 0, 0))

  test 'moment(one-arg) complains', ->
    err = null
    try
      tz.moment('June 24 at 10:00pm')
    catch err
    ok err.toString().match(/^Error: tz.moment only works on /)

  test 'moment(non-string, fmt-string) complains', ->
    err = null
    try
      tz.moment(moonwalk, 'MMMM D h:mmA')
    catch err
    ok err.toString().match(/^Error: tz.moment only works on /)

  test 'moment(date-string, non-string) complains', ->
    err = null
    try
      tz.moment('June 24 at 10:00pm', 123)
    catch err
    ok err.toString().match(/^Error: tz.moment only works on /)

  test 'moment(date-string, fmt-string) works', ->
    ok tz.moment('June 24 at 10:00pm', 'MMMM D h:mmA')

  test 'moment(date-string, [fmt-strings]) works', ->
    ok tz.moment('June 24 at 10:00pm', ['MMMM D h:mmA', 'L'])

  test 'moment passes through invalid results', ->
    m = tz.moment('not a valid date', 'L')
    ok !m.isValid()

  test 'moment accepts excess input, but all format used', ->
    m = tz.moment('12pm and more', 'ha')
    ok m.isValid()

  test 'moment rejects excess format', ->
    m = tz.moment('12pm', 'h:mma')
    ok !m.isValid()

  test 'moment returns moment for valid results', ->
    m = tz.moment('June 24, 2015 at 10:00pm -04:00', 'MMMM D, YYYY h:mmA Z')
    ok m.isValid()

  test 'moment sans-timezone info parses according to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    expected = new Date(1435197600000) # 10pm EDT on June 24, 2015
    m = tz.moment('June 24, 2015 at 10:00pm', 'MMMM D, YYYY h:mmA')
    equal +m.toDate(), +expected

  test 'moment with-timezone info parses according to that timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    expected = new Date(1435204800000) # 10pm MDT on June 24, 2015
    m = tz.moment('June 24, 2015 at 10:00pm -06:00', 'MMMM D, YYYY h:mmA Z')
    equal +m.toDate(), +expected

  test 'moment can change locales with single arity', ->
    tz.changeLocale("en_US", "en")
    m1 = tz.moment('mercredi 1 juillet 2015 15:00', 'LLLL');
    ok !m1._locale._abbr.match(/fr/)
    ok !m1.isValid()

    tz.changeLocale("fr_FR", "fr")
    m2 = tz.moment('mercredi 1 juillet 2015 15:00', 'LLLL');
    ok m2._locale._abbr.match(/fr/)
    ok m2.isValid()

  test 'moment can change locales with multiple arity', ->
    tz.changeLocale("en_US", "en")
    m1 = tz.moment('mercredi 1 juillet 2015 15:00', 'LLLL');
    ok !m1._locale._abbr.match(/fr/)
    ok !m1.isValid()

    tz.changeLocale(french, "fr_FR", "fr")
    m2 = tz.moment('mercredi 1 juillet 2015 15:00', 'LLLL');
    ok m2._locale._abbr.match(/fr/)
    ok m2.isValid()

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

  test 'parse(integer) should be ms since epoch', ->
    equal +tz.parse(2016), +tz.raw_parse(2016)

  test 'parse("looks like integer") should be a year', ->
    equal +tz.parse('2016'), +tz.parse('2016-01-01')

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
    tz.changeLocale(french, 'fr_FR', 'fr')
    equal tz.format(time, '%-l%P'), "15"
    equal tz.format(time, '%I%P'), "15"
    equal tz.format(time, '%r'), "15:00:00"

  test "format() should recognize date.formats.*", ->
    I18nStubber.stub 'en', 'date.formats.short': '%b %-d'
    equal tz.format(moonwalk, 'date.formats.short'), "Jul 21"

  test "format() should recognize time.formats.*", ->
    I18nStubber.stub 'en', 'time.formats.tiny': '%-l:%M%P'
    equal tz.format(epoch, 'time.formats.tiny'), "12:00am"

  test "format() should localize when given a localization key", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'date.formats.full': '%-d %b %Y %-l:%M%P'
    equal tz.format(moonwalk, 'date.formats.full'), "21 juil. 1969 2:56"

  test "format() should automatically convert %l to %-l when given a localization key", ->
    I18nStubber.stub 'en', 'time.formats.tiny': '%l:%M%P'
    equal tz.format(moonwalk, 'time.formats.tiny'), "2:56am"

  test "format() should automatically convert %k to %-k when given a localization key", ->
    I18nStubber.stub 'en', 'time.formats.tiny': '%k:%M'
    equal tz.format(moonwalk, 'time.formats.tiny'), "2:56"

  test "format() should automatically convert %e to %-e when given a localization key", ->
    I18nStubber.stub 'en', 'date.formats.short': '%b %e'
    equal tz.format(epoch, 'date.formats.short'), "Jan 1"

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
    tz.changeLocale(french, 'fr_FR', 'fr')
    equal tz.format(moonwalk, '%c'), "lun. 21 juil. 1969 02:56:00 UTC"

  test 'changeLocale(...) should asynchronously curry in a locale by name', ->
    expect(1)
    stop()
    tz.changeLocale('fr_FR', 'fr').then ->
      start()
      equal tz.format(moonwalk, '%c'), "lun. 21 juil. 1969 02:56:00 UTC"

  test 'changeZone(...) should synchronously curry if pre-loaded', ->
    tz.preload('America/Detroit', detroit)
    tz.changeZone('America/Detroit')
    equal tz.format(moonwalk, '%c'), "Sun 20 Jul 1969 09:56:00 PM EST"

  test "hasMeridian() true if locale defines am/pm", ->
    ok tz.hasMeridian()

  test "hasMeridian() false if locale doesn't define am/pm", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    ok !tz.hasMeridian()

  test "useMeridian() true if locale defines am/pm and uses 12-hour format", ->
    I18nStubber.stub 'en', 'time.formats.tiny': '%l:%M%P'
    ok tz.hasMeridian()
    ok tz.useMeridian()

  test "useMeridian() false if locale defines am/pm but uses 24-hour format", ->
    I18nStubber.stub 'en', 'time.formats.tiny': '%k:%M'
    ok tz.hasMeridian()
    ok !tz.useMeridian()

  test "useMeridian() false if locale doesn't define am/pm and instead uses 24-hour format", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'time.formats.tiny': '%-k:%M'
    ok !tz.hasMeridian()
    ok !tz.useMeridian()

  test "useMeridian() false if locale doesn't define am/pm but still uses 12-hour format (format will be corrected)", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'time.formats.tiny': '%-l:%M%P'
    ok !tz.hasMeridian()
    ok !tz.useMeridian()

  test "isMidnight() is false when no argument given.", ->
    ok !tz.isMidnight()

  test "isMidnight() is false when invalid date is given.", ->
    date = new Date("invalid date")
    ok !tz.isMidnight(date)

  test "isMidnight() is true when date given is at midnight.", ->
    ok tz.isMidnight(epoch)

  test "isMidnight() is false when date given isn't at midnight.", ->
    ok !tz.isMidnight(moonwalk)

  test "isMidnight() is false when date is midnight in a different zone.", ->
    tz.changeZone(detroit, 'America/Detroit')
    ok !tz.isMidnight(epoch)

  test "changeToTheSecondBeforeMidnight() returns null when no argument given.", ->
    equal tz.changeToTheSecondBeforeMidnight(), null

  test "changeToTheSecondBeforeMidnight() returns null when invalid date is given.", ->
    date = new Date("invalid date")
    equal tz.changeToTheSecondBeforeMidnight(date), null

  test "changeToTheSecondBeforeMidnight() returns fancy midnight when a valid date is given.", ->
    fancyMidnight = tz.changeToTheSecondBeforeMidnight(epoch)
    equal fancyMidnight.toGMTString(), "Thu, 01 Jan 1970 23:59:59 GMT"

  test "mergeTimeAndDate() finds the given time of day on the given date.", ->
    equal +tz.mergeTimeAndDate(moonwalk, epoch), +(new Date(Date.UTC(1970, 0, 1, 2, 56)))

  module 'english tz',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      I18nStubber.setLocale 'en_US'
      I18nStubber.stub 'en_US',
        "date.formats.date_at_time": "%b %-d at %l:%M%P"
        "date.formats.default": "%Y-%m-%d"
        "date.formats.full": "%b %-d, %Y %-l:%M%P"
        "date.formats.full_with_weekday": "%a %b %-d, %Y %-l:%M%P"
        "date.formats.long": "%B %-d, %Y"
        "date.formats.long_with_weekday": "%A, %B %-d"
        "date.formats.medium": "%b %-d, %Y"
        "date.formats.medium_month": "%b %Y"
        "date.formats.medium_with_weekday": "%a %b %-d, %Y"
        "date.formats.short": "%b %-d"
        "date.formats.short_month": "%b"
        "date.formats.short_weekday": "%a"
        "date.formats.short_with_weekday": "%a, %b %-d"
        "date.formats.weekday": "%A"
        "time.formats.default": "%a, %d %b %Y %H:%M:%S %z"
        "time.formats.long": "%B %d, %Y %H:%M"
        "time.formats.short": "%d %b %H:%M"
        "time.formats.tiny": "%l:%M%P"
        "time.formats.tiny_on_the_hour": "%l%P"
      tz.changeLocale("en_US", "en")

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'parses english dates', ->
    engDates = [
      "08/03/2015",
      "8/3/2015",
      "August 3, 2015",
      "Aug 3, 2015",
      "3 Aug 2015",
      "2015-08-03",
      "2015 08 03",
      "August 3, 2015",
      "Monday, August 3",
      "Mon Aug 3, 2015",
      "Mon, Aug 3",
      "Aug 3"
    ]

    _.each engDates, (date) ->
      d = tz.parse(date)
      equal tz.format(d, '%d'), '03', "this works: #{date}"

  test 'parses english times', ->
    engTimes = [
      "6:06 PM",
      "6:06:22 PM",
      "6:06pm",
      "6pm"
    ]

    _.each engTimes, (time) ->
      d = tz.parse(time)
      equal tz.format(d, '%H'), '18', "this works: #{time}"

  test 'parses english date times', ->
    engDateTimes = [
      "2015-08-03 18:06:22",
      "August 3, 2015 6:06 PM",
      "Aug 3, 2015 6:06 PM",
      "Aug 3, 2015 6pm",
      "Monday, August 3, 2015 6:06 PM",
      "Mon, Aug 3, 2015 6:06 PM",
      "Aug 3 at 6:06pm",
      "Aug 3, 2015 6:06pm",
      "Mon Aug 3, 2015 6:06pm"
    ]

    _.each engDateTimes, (dateTime) ->
      d = tz.parse(dateTime)
      equal tz.format(d, '%d %H'), '03 18', "this works: #{dateTime}"

  test 'parses 24hr times even if the locale lacks them', ->
    d = tz.parse('18:06')
    equal tz.format(d, '%H:%M'), '18:06'

  module 'french tz',
    setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      I18nStubber.setLocale 'fr_FR'
      I18nStubber.stub 'fr_FR',
        "date.formats.date_at_time": "%-d %b à %k:%M"
        "date.formats.default": "%d/%m/%Y"
        "date.formats.full": "%b %-d, %Y %-k:%M"
        "date.formats.full_with_weekday": "%a %-d %b, %Y %-k:%M"
        "date.formats.long": "le %-d %B %Y"
        "date.formats.long_with_weekday": "%A, %-d %B"
        "date.formats.medium": "%-d %b %Y"
        "date.formats.medium_month": "%b %Y"
        "date.formats.medium_with_weekday": "%a %-d %b %Y"
        "date.formats.short": "%-d %b"
        "date.formats.short_month": "%b"
        "date.formats.short_weekday": "%a"
        "date.formats.short_with_weekday": "%a, %-d %b"
        "date.formats.weekday": "%A"
        "time.formats.default": "%a, %d %b %Y %H:%M:%S %z"
        "time.formats.long": " %d %B, %Y %H:%M"
        "time.formats.short": "%d %b %H:%M"
        "time.formats.tiny": "%k:%M"
        "time.formats.tiny_on_the_hour": "%k:%M"
      tz.changeLocale(french, "fr_FR", "fr")

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'parses french dates', ->
    frenchDates = [
      "03/08/2015",
      "3/8/2015",
      "3 août 2015",
      "2015-08-03",
      "le 3 août 2015",
      "lundi, 3 août",
      "lun. 3 août 2015",
      "3 août",
      "lun., 3 août",
      "3 août 2015"
      "3 août"
    ]

    _.each frenchDates, (date) ->
      d = tz.parse(date)
      equal tz.format(d, '%d'), '03', "this works: #{date}"

  test 'parses french times', ->
    frenchTimes = [
      "18:06"
      "18:06:22"
    ]

    _.each frenchTimes, (time) ->
      d = tz.parse(time)
      equal tz.format(d, '%H'), '18', "this works: #{time}"

  test 'parses french date times', ->
    frenchDateTimes = [
      "2015-08-03 18:06:22",
      "3 août 2015 18:06",
      "lundi 3 août 2015 18:06",
      "lun. 3 août 2015 18:06",
      "3 août à 18:06",
      "août 3, 2015 18:06",
      "lun. 3 août, 2015 18:06"
    ]

    _.each frenchDateTimes, (dateTime) ->
      d = tz.parse(dateTime)
      equal tz.format(d, '%d %H'), '03 18', "this works: #{dateTime}"

  module 'chinese tz',
    setup: ->
      setup: ->
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      I18nStubber.setLocale 'zh_CN'
      I18nStubber.stub 'zh_CN',
        "date.formats.date_at_time": "%b %-d 于 %H:%M"
        "date.formats.default": "%Y-%m-%d"
        "date.formats.full": "%b %-d, %Y %-l:%M%P"
        "date.formats.full_with_weekday": "%a %b %-d, %Y %-l:%M%P"
        "date.formats.long": "%Y %B %-d"
        "date.formats.long_with_weekday": "%A, %B %-d"
        "date.formats.medium": "%Y %b %-d"
        "date.formats.medium_month": "%Y %b"
        "date.formats.medium_with_weekday": "%a %Y %b %-d"
        "date.formats.short": "%b %-d"
        "date.formats.short_month": "%b"
        "date.formats.short_weekday": "%a"
        "date.formats.short_with_weekday": "%a, %b %-d"
        "date.formats.weekday": "%A"
        "time.formats.default": "%a, %Y %b %d  %H:%M:%S %z"
        "time.formats.long": "%Y %B %d %H:%M"
        "time.formats.short": "%b %d %H:%M"
        "time.formats.tiny": "%H:%M"
        "time.formats.tiny_on_the_hour": "%k:%M"
      tz.changeLocale(chinese, "zh_CN", "zh-cn")

    teardown: ->
      tz.restore(@snapshot)
      I18nStubber.popFrame()

  test 'parses chinese dates', ->
    chineseDates = [
      "2015-08-03",
      "2015年8月3日",
      "2015 八月 3",
      "2015 8月 3",
      "星期一, 八月 3",
      "一 2015 8月 3",
      "一, 8月 3",
      "8月 3"
    ]

    _.each chineseDates, (date) ->
      d = tz.parse(date)
      equal tz.format(d, '%d'), '03', "this works: #{date}"

  test 'parses chinese dates', ->
    chineseTimes = [
      "晚上6点06分",
      "晚上6点6分22秒",
      "18:06"
    ]

    _.each chineseTimes, (time) ->
      d = tz.parse(time)
      equal tz.format(d, '%H'), '18', "this works: #{time}"

  test 'parses chinese date times', ->
    chineseDateTimes = [
      "2015-08-03 18:06:22",
      "2015年8月3日晚上6点06分",
      "2015年8月3日星期一晚上6点06分",
      "8月 3 于 18:06",
      "8月 3, 2015 6:06下午",
      "一 8月 3, 2015 6:06下午"
    ]

    _.each chineseDateTimes, (dateTime) ->
      d = tz.parse(dateTime)
      equal tz.format(d, '%d %H'), '03 18', "this works: #{dateTime}"
