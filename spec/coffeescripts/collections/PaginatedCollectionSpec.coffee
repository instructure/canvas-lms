define [
  'jquery'
  'Backbone'
  'compiled/collections/PaginatedCollection'
  'helpers/getFakePage'
], ($, Backbone, PaginatedCollection, getFakePage) ->

  module 'PaginatedCollection',
    setup: ->
      @server = sinon.fakeServer.create()
      @collection = new PaginatedCollection null,
        params:
          multi: ['foos', 'bars']
          single: 1
      @collection.url = '/test'
      @collection.urlWithParams = -> @url + '?' + $.param(@options.params)
      @collection.model = Backbone.Model.extend()
      @server.sendPage = (page, url) ->
        @respond 'GET', url, [200, {
          'Content-Type': 'application/json'
          'Link': page.header
        }, JSON.stringify page.data]

    teardown: ->
      @server.restore()

  test 'fetch maintains parent API', 6,  ->
    page = getFakePage()
    dfd = @collection.fetch success: (self, response) =>
      equal self, @collection, 'passes itself into success handler'
      deepEqual response, page.data, 'passes response into success handler'
    ok dfd.promise, 'returns a deferred object (quacks like a deferred)'
    dfd.done (data, status, xhr) =>
      deepEqual data, page.data, 'deferred is resolved with raw data'
      equal status, 'success', 'text status is success'
      ok xhr.abort 'function', 'jQuery xhr is passed in (quacks like a xhr)'
    @server.sendPage page, @collection.urlWithParams()

  test 'fetch maintains error handler API', 2, ->
    @collection.fetch error: (self, xhr) =>
      equal self, @collection, 'passes itself into fail handler'
      deepEqual xhr.responseText, 'wah wah', 'passes response into fail handler'
    @server.respond 'GET', @collection.urlWithParams(), [400, {'Content-Type': 'application/json'}, 'wah wah']

  test 'fetch fires fetch event', 3,  ->
    page = getFakePage()
    @collection.on 'fetch', (self, modelData) =>
      ok true, 'triggers fetch'
      deepEqual modelData, page.data, 'passes data in'
      equal self, @collection, 'passes self in'
    @collection.fetch()
    @server.sendPage page, @collection.urlWithParams()

  test 'fetches current page', 10, ->
    page1 = getFakePage 1

    @collection.fetch success: =>
      equal @collection.models.length, 2, 'added models to collection'
      equal @collection.models[0].get('id'), 1, 'added model to collection'
      equal @collection.models[1].get('id'), 2, 'added model to collection'
      equal @collection.urls.current, page1.urls.current, 'current url matches'
    @server.sendPage page1, @collection.urlWithParams()

    @collection.on 'fetch:current', (self, modelData) ->
      ok true, 'triggers fetch:current event'
      deepEqual modelData, page1.data, 'passes data in'
    @collection.fetch page: 'current', success: =>
      equal @collection.models.length, 2, 'added models to collection'
      equal @collection.models[0].get('id'), 1, 'passed in model to current page handler'
      equal @collection.models[1].get('id'), 2, 'passed in model to current page handler'
      equal @collection.urls.current, page1.urls.current, 'current url matches'
    @server.sendPage page1, @collection.urls.current

  test 'fetches next page', 8, ->
    page1 = getFakePage 1
    page2 = getFakePage 2

    @collection.fetch success: =>
      equal @collection.models[0].get('id'), 1, 'added model to collection'
      equal @collection.models[1].get('id'), 2, 'added model to collection'
      equal @collection.urls.next, page1.urls.next, 'next url matches'
    @server.sendPage page1, @collection.urlWithParams()

    @collection.on 'fetch:next', (self, modelData) ->
      ok true, 'triggers fetch:next event'
      deepEqual modelData, page2.data, 'passes data in'
    @collection.fetch page: 'next', success: =>
      equal @collection.models[2].get('id'), 3, 'passed in model to next page handler'
      equal @collection.models[3].get('id'), 4, 'passed in model to next page handler'
      equal @collection.urls.next, page2.urls.next, 'next url matches'
    @server.sendPage page2, @collection.urls.next

  test 'fetches previous page', 8, ->
    page1 = getFakePage 1
    page2 = getFakePage 2

    @collection.fetch success: =>
      equal @collection.models[0].get('id'), 3, 'added model to collection'
      equal @collection.models[1].get('id'), 4, 'added model to collection'
      equal @collection.urls.prev, page2.urls.prev, 'prev url matches'

    @server.sendPage page2, @collection.urlWithParams()

    @collection.on 'fetch:prev', (self, modelData) ->
      ok true, 'triggers fetch:prev event'
      deepEqual modelData, page1.data, 'passes data in'

    @collection.fetch page: 'prev', success: =>
      equal @collection.models[2].get('id'), 1, 'passed in model to prev page handler'
      equal @collection.models[3].get('id'), 2, 'passed in model to prev page handler'
      equal @collection.urls.prev, undefined, 'prev url not set when there is not one'

    @server.sendPage page1, @collection.urls.prev

  test 'fetches current, prev, next, top and bottom pages', 8, ->
    page1 = getFakePage 1
    page2 = getFakePage 2
    page3 = getFakePage 3
    page4 = getFakePage 4

    @collection.fetch success: =>
      equal @collection.models[0].get('id'), 5, 'added model to collection'
      expectedUrls = page3.urls
      expectedUrls.top = page3.urls.prev
      expectedUrls.bottom = page3.urls.next
      deepEqual @collection.urls, expectedUrls, 'urls are as expected for fetch'
    @server.sendPage page3, @collection.urlWithParams()

    @collection.fetch page: 'current', success: =>
      expectedUrls = page3.urls
      expectedUrls.top = page3.urls.prev
      expectedUrls.bottom = page3.urls.next
      deepEqual @collection.urls, expectedUrls, 'urls are as expected for fetch current'
    @server.sendPage page3, @collection.urlWithParams()

    @collection.fetch page: 'prev', success: =>
      equal @collection.models.length, 4, 'added models to collection'
      expectedUrls = page2.urls
      expectedUrls.top = page2.urls.prev
      expectedUrls.bottom = page3.urls.next # shouldn't change
      deepEqual @collection.urls, expectedUrls, 'urls are as expected fetch prev'
    @server.sendPage page2, @collection.urls.prev

    @collection.fetch page: 'top', success: =>
      equal @collection.models.length, 6, 'added models to collection'
      expectedUrls = page1.urls
      expectedUrls.bottom = page3.urls.next # shouldn't change
      deepEqual @collection.urls, expectedUrls, 'urls are as expected for fetch top'
    @server.sendPage page1, @collection.urls.top

    @collection.fetch page: 'bottom', success: =>
      equal @collection.models.length, 8, 'added models to collection'
      equal @collection.urls.bottom, page4.urls.next
    @server.sendPage page4, @collection.urls.bottom

