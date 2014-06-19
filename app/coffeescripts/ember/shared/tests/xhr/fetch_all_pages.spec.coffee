define [
  'ember'
  '../../xhr/fetch_all_pages'
  '../shared_ajax_fixtures'
], ({ArrayProxy}, fetchAllPages, fixtures) ->

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

  # TODO: test pagination and request data

  asyncTest 'calls process if provided', ->
    fetchAllPages(ENV.numbers_url, process: (response) ->
      response.map (x) -> x * 2
    ).promise.then (records) ->
      start()
      deepEqual(records.get('content'), [2, 4, 6])
