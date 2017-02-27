define [
  'ember'
  '../../xhr/fetch_all_pages'
  '../shared_ajax_fixtures'
], (Ember, fetchAllPages, fixtures) ->

  ArrayProxy = Ember.ArrayProxy

  QUnit.module 'Fetch all pages component',
    setup: ->
      # yes, this looks weird.  if you run
      # screenreader gradebook tests before this, it puts
      # ember into test mode, and everything dies here when we
      # try to do asynchronous work.  This spec was originally written
      # assuming that Ember was unmodified.  This will not impact the
      #  screenreader gradebook tests, because they call "setupForTesting"
      #  in every setup.
      Ember.testing = false
      fixtures.create()

  asyncTest 'passes records through by default', ->
    fetchAllPages(ENV.numbers_url).promise.then (records) ->
      start()
      deepEqual(records.get('content'), [1, 2, 3])


  asyncTest 'populates existing array if provided', ->
    myArray = ArrayProxy.create({content: []})
    fetchAllPages(ENV.numbers_url, records: myArray).promise.then ->
      start()
      deepEqual(myArray.get('content'), [1, 2, 3])

  asyncTest 'calls process if provided', ->
    fetchAllPages(ENV.numbers_url, process: (response) ->
      response.map (x) -> x * 2
    ).promise.then (records) ->
      start()
      deepEqual(records.get('content'), [2, 4, 6])
