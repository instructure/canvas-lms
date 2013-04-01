define [
  'jquery'
  'compiled/collections/PaginatedCollection'
  'compiled/views/PaginatedCollectionView'
  'helpers/getFakePage'
], ($, PaginatedCollection, PaginatedCollectionView, fakePage) ->

  server = null
  collection = null
  view = null
  fixtures = $ '#fixtures'

  createServer = ->
    server = sinon.fakeServer.create()
    server.sendPage = (page, url) ->
      @respond 'GET', url, [200, {
        'Content-Type': 'application/json'
        'Link': page.header
      }, JSON.stringify page.data]

  class ItemView extends Backbone.View
    tagName: 'li'
    template: ({id}) -> id
    initialize: ->
      # make some scrolly happen
      @$el.css 'height', 100

  class TestCollection extends PaginatedCollection
    url: '/test'

  module 'PaginatedCollectionView',
    setup: ->
      fixtures.css height: 100, overflow: 'auto'
      createServer()
      collection = new TestCollection
      view = new PaginatedCollectionView
        collection: collection
        itemView: ItemView
        scrollContainer: fixtures
      view.$el.appendTo fixtures
      view.render()

    teardown: ->
      server.restore()
      fixtures.attr 'style', ''
      view.remove()

  assertItemRendered = (id) ->
    $match = view.$list.children().filter (i, el) -> el.innerHTML is id
    ok $match.length, 'item found'

  scrollToBottom = ->
    fixtures[0].scrollTop = fixtures[0].scrollHeight
    ok fixtures[0].scrollTop > 0

  test 'renders items', ->
    collection.add id: 1
    assertItemRendered '1'

  test 'renders items on collection fetch and fetch next', ->
    collection.fetch()
    server.sendPage fakePage(), collection.url
    assertItemRendered '1'
    assertItemRendered '2'
    collection.fetch page: 'next'
    server.sendPage fakePage(2), collection.urls.next
    assertItemRendered '3'
    assertItemRendered '4'

  test 'fetches the next page on scroll', ->
    collection.fetch()
    server.sendPage fakePage(), collection.url
    scrollToBottom()
    # scroll event isn't firing in the test :( manually calling checkScroll
    view.checkScroll()
    ok collection.fetchingNextPage, 'collection is fetching'
    server.sendPage fakePage(2), collection.urls.next
    assertItemRendered '3'
    assertItemRendered '4'

  test 'stops fetching pages after the last page', ->
    # see later in the test why this exists
    fakeEvent = "foo.pagination:#{view.cid}"
    fixtures.on fakeEvent, ->
      ok false, 'this should never run'
    collection.fetch()
    server.sendPage fakePage(), collection.url
    for i in [2..10]
      collection.fetch page: 'next'
      server.sendPage fakePage(i), collection.urls.next
    assertItemRendered '1'
    assertItemRendered '20'
    # this is ghetto, but data('events') is no longer around and I can't get
    # the scroll events to trigger, but this works because the
    # ".pagination:#{view.cid}" events are all wipe out on last fetch, so the
    # assertion at the beginning of the test in the handler shouldn't fire
    fixtures.trigger fakeEvent

