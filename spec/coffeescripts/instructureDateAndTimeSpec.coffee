define [
  'jquery'
  'jquery.instructure_date_and_time'
], ($) ->
  module 'parseFromISO'

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
