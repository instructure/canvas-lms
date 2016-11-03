define [
  '../mockFilesENV'
  'jquery'
  'react'
  'react-dom'
  'compiled/react_files/components/SearchResults'
  'compiled/collections/FilesCollection'
], (mockFilesENV, $, React, ReactDOM, SearchResults, FilesCollection) ->

  module 'SearchResults#render',
    setup: ->
    teardown: ->
      $("#fixtures").empty()

  # asyncTest 'when collection is loaded and empty display no matches found', ->
  #   expect(1)

  #   container = $('<div>').appendTo("#fixtures")[0]
  #   renderedRoutes = ReactDOM.renderComponent(routes, container)

  #   @server = sinon.fakeServer.create()
  #   @server.respondWith('GET', new RegExp('/api/v1/courses/999/files?search_term=fake_search_term'), '[]')

  #   renderedRoutes.dispatch '/courses/999/files/search?search_term=fake_search_term', =>
  #     @server.respond()


  #     ok $(container).find(':contains(Your search - "fake_search_term" - did not match any files.)').length, 'displays no matches error'
  #     ReactDOM.unmountComponentAtNode(container)
  #     @server.restore()
  #     start()
