define [
  'jquery'
  'compiled/collections/PaginatedCollection'
  'compiled/views/SharedPaginatedCollectionView'
  'helpers/getFakePage'
], ($, PaginatedCollection, SharedPaginatedCollectionView, fakePage) ->

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
      @$el.css 'height', 100

  class TestCollection extends PaginatedCollection
    url: '/test'

  module 'SharedPaginatedCollectionView',
    setup: ->
      fixtures.css height: 100, overflow: 'auto'
      createServer()
      collection = new TestCollection
      view = new SharedPaginatedCollectionView
        collection: collection
        itemView: ItemView
        scrollContainer: fixtures
      view.$el.appendTo fixtures
      view.render()
      fixtures.append $("<div style='height: 1000px;'>space hog</div>")

    teardown: ->
      server.restore()
      fixtures.attr 'style', ''
      view.remove()

  assertItemRendered = (id) ->
    $match = view.$list.children().filter (i, el) -> el.innerHTML is id
    ok $match.length, 'item found'

  test 'fetches the next page when scrolled to the end of the $el (not the scrollContainer)', ->
    collection.fetch()
    server.sendPage fakePage(), collection.url
    fixtures.scrollTop(200)
    view.checkScroll()
    ok collection.fetchingNextPage, 'collection is fetching'
    server.sendPage fakePage(2), collection.urls.next
    assertItemRendered '3'
    assertItemRendered '4'
