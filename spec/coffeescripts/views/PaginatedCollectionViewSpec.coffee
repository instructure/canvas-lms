define [
  'jquery'
  'Backbone'
  'compiled/collections/PaginatedCollection'
  'compiled/views/PaginatedCollectionView'
  'helpers/getFakePage'
  'helpers/fakeENV'
], ($, Backbone, PaginatedCollection, PaginatedCollectionView, fakePage, fakeENV) ->

  server = null
  clock = null
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
      super
      # make some scrolly happen
      @$el.css 'height', 500

  class TestCollection extends PaginatedCollection
    url: '/test'

  QUnit.module 'PaginatedCollectionView',
    setup: ->
      fakeENV.setup()
      fixtures.css height: 500, overflow: 'auto'
      createServer()
      clock = sinon.useFakeTimers()
      collection = new TestCollection
      view = new PaginatedCollectionView
        collection: collection
        itemView: ItemView
        scrollContainer: fixtures
      view.$el.appendTo fixtures
      view.render()

    teardown: ->
      fakeENV.teardown()
      server.restore()
      clock.restore()
      fixtures.attr 'style', ''
      view.remove()

  assertItemRendered = (id) ->
    $match = view.$list.children().filter (i, el) -> el.innerHTML is id
    ok $match.length, 'item found'

  scrollToBottom = ->
    # scroll within 100px of the bottom of the current list (<500 triggers a fetch)
    fixtures[0].scrollTop = view.$el.position().top +
      view.$el.height() -
      fixtures.position().top -
      100
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

  test 'doesn\'t fetch if already fetching', ->
    @spy collection, 'fetch'
    @spy view, 'hideLoadingIndicator'
    collection.fetch()
    view.checkScroll()
    ok collection.fetch.calledOnce, 'fetch called once'
    ok !view.hideLoadingIndicator.called, 'hideLoadingIndicator not called'

  test 'auto-fetches visible pages', ->
    view.remove()
    view = new PaginatedCollectionView
      collection: collection
      itemView: ItemView
      scrollContainer: fixtures
      autoFetch: true
    view.$el.appendTo fixtures
    view.render()
    fixtures.css height: 1000 # it will autofetch the second page, since we're within the threshold

    collection.fetch()
    server.sendPage fakePage(), collection.url
    assertItemRendered '1'
    assertItemRendered '2'
    clock.tick(0)
    server.sendPage fakePage(2), collection.urls.next
    assertItemRendered '3'
    assertItemRendered '4'

  test 'fetches every page until it reaches the last when fetchItAll is set', ->
    view.remove()
    view = new PaginatedCollectionView
      collection: collection
      itemView: ItemView
      scrollContainer: fixtures
      fetchItAll: true
    view.$el.appendTo fixtures
    view.render()
    fixtures.css height: 1 # to show that it will continue to load in the background even if it's filled the current view height

    collection.fetch()
    server.sendPage fakePage(), collection.url
    assertItemRendered '1'
    assertItemRendered '2'
    clock.tick(0)
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
