define [
  'jquery'
  'jquery.instructure_date_and_time'
], ($) ->
  module 'parseFromISO'

  test '$.parseFromISO() should have valid: true on success', ->
    equal $.parseFromISO('2013-09-23T00:00:00Z').valid, true

  test '$.parseFromISO() should have valid: false on failure', ->
    equal $.parseFromISO(null).valid, false
    equal $.parseFromISO('yyyy-mm-dd').valid, false
