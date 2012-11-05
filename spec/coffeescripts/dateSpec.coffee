define [ 'vendor/date' ], ->

  module 'Date'

  test 'Date.parse', ->
    # create the same date the "new Date" would if the browser were in UTC
    utc = (yr, mon, day, hr, min, sec) ->
      date = new Date yr, mon, day, hr, min, sec
      date.addMinutes -date.getTimezoneOffset()

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
      sinon.stub(date, 'getTimezoneOffset').returns(Number(offset))
      equal date.getUTCOffset(), expectedResult
