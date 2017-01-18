define [
  'underscore'
  'jsx/gradebook/grid/helpers/depaginator'
], (_, Depaginate) ->

  fakeData = ->
    data = []
    _.times 50, (n) ->
      data.push { id: n, data: 'excellent data number ' + n }
    data

  linkHeader = (url, pageNumber) ->
    '<' + url + '?page=1&per_page=50>;' +
      'rel="current",<' + url + '?page=' + pageNumber + '&per_page=50>;' +
      'rel="first",<' + url + '?page=5&per_page=50>;rel="last"'

  paginatedResponse = (pageNumber, url, data) ->
    response = [
      200,
      { "Content-Type": "application/json","Link": linkHeader(url, pageNumber) },
      JSON.stringify data
    ]
    response

  serverWithPaginatedResponses = (url, pageCount) ->
    server = sinon.fakeServer.create()
    data = fakeData()
    server.respondWith(
      "GET",
      url,
      paginatedResponse(1, url, data)
    )
    _.times pageCount - 1, (n) ->
      currentPage = n + 2
      server.respondWith(
        "GET",
        url + '?page=' + currentPage,
        paginatedResponse(currentPage, url, data)
      )
    server

  module 'Depaginator',
    setup: ->
      @url = 'http://www.example.com/api/v1/courses/1/fakedata'
      @server = serverWithPaginatedResponses(@url, 5)
    teardown: ->
      @server.restore()


  test 'can handle multiple pages of data', ->
    promise = Depaginate(@url)
    @server.respond()
    result = null
    promise.then (val) -> result = val
    @server.respond()
    deepEqual result.length, 250
