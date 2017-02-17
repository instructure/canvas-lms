define [ 'vendor/date' ], () ->

  QUnit.module 'Date'

  test 'Date.parse', ->
    # create the same date the "new Date" would if the browser were in UTC
    utc = -> new Date Date.UTC arguments...

    examples =
      # Mountain
      "Wed May 2 2012 00:00:00 MST": utc(2012, 4, 2,  7,  0, 0)
      "Wed May 2 2012 00:00:00 MDT": utc(2012, 4, 2,  6,  0, 0)
      "2012-05-02T00:00:00-06:00":   utc(2012, 4, 2,  6,  0, 0)

      # variations on UTC
      "Wed May 2 2012 00:00:00 UTC": utc(2012, 4, 2,  0,  0, 0)
      "Wed May 2 2012 00:00:00 GMT": utc(2012, 4, 2,  0,  0, 0)
      "2012-05-02T00:00:00Z":        utc(2012, 4, 2,  0,  0, 0)
      "2012-05-02T00:00:00-0000":    utc(2012, 4, 2,  0,  0, 0)
      "2012-05-02T00:00:00+0000":    utc(2012, 4, 2,  0,  0, 0)
      "2012-05-02T00:00:00+00:00":   utc(2012, 4, 2,  0,  0, 0)
      "2012-05-02T00:00:00-00:00":   utc(2012, 4, 2,  0,  0, 0)

      # partial-hour values
      "2012-05-02T00:00:00+02:30":    utc(2012, 4, 1, 21, 30, 0)
      "2012-05-02T00:00:00-02:30":    utc(2012, 4, 2,  2, 30, 0)
      "2012-05-02T00:00:00+01:01":    utc(2012, 4, 1, 22, 59, 0)
      "2012-05-02T00:00:00-01:01":    utc(2012, 4, 2,  1,  1, 0)
      "2012-05-02T00:00:00+01:59":    utc(2012, 4, 1, 22,  1, 0)
      "2012-05-02T00:00:00-01:59":    utc(2012, 4, 2,  1, 59, 0)
      "2012-05-02T00:00:00+00:01":    utc(2012, 4, 1, 23, 59, 0)
      "2012-05-02T00:00:00-00:01":    utc(2012, 4, 2,  0,  1, 0)

      # DST-ends edge case
      "2012-11-04T01:00:00-06:00":    utc(2012, 10, 4,  7,  0, 0)

    for dateString, expectedDate of examples
      equal Date.parse(dateString).valueOf(), expectedDate.valueOf()

  test 'date.getUTCOffset', ->
    examples =
      # Mountain
      ' 360': '-0600'
      ' 420': '-0700'

      # UTC
      '   0': '+0000'

      # partial-hour values
      '-150': '+0230'
      ' 150': '-0230'
      ' -61': '+0101'
      '  61': '-0101'
      '-119': '+0159'
      ' 119': '-0159'
      '  -1': '+0001'
      '   1': '-0001'

    for offset, expectedResult of examples
      date = new Date
      @stub(date, 'getTimezoneOffset').returns(Number(offset))
      equal date.getUTCOffset(), expectedResult

  test 'date.add* at DST-end', ->
    # 1ms before 1am on day of DST-end
    date = new Date 2012, 10, 4, 0, 59, 59, 999

    # date.set* modifies in place, so we clone, but doesn't return the date
    # object, returning ms-since-epoch instead. fortunately, new Date
    # ms-since-epoch works, so we do that rather than introducing a bunch of
    # temporary variables
    ok date.clone().addMilliseconds(1).equals(new Date date.clone().setUTCMilliseconds 1000)
    ok date.clone().addSeconds(1).equals(new Date date.clone().setUTCSeconds 60)
    ok date.clone().addMinutes(1).equals(new Date date.clone().setUTCMinutes 60)
    ok date.clone().addHours(1).equals(new Date date.clone().setUTCHours date.getUTCHours() + 1)

  test 'date.set at DST-end', ->
    date = new Date 2012, 10, 4, 0, 0, 0
    date.set(hour: 14)
    ok date.getHours() == 14
    date.set(hour: 1)
    ok date.getHours() == 1
