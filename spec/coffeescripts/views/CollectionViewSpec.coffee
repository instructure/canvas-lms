define [
  'jquery'
  'Backbone'
  'compiled/views/CollectionView'
  'helpers/fakeENV'
], ($, Backbone, CollectionView, fakeENV) ->

  collection = null
  view = null

  class Collection extends Backbone.Collection
    model: Backbone.Model
    comparator: (a, b) ->
      if a.get('id') < b.get('id') then 1 else -1

  class ItemView extends Backbone.View
    tagName: 'li'
    template: ({name}) -> name
    remove: ->
      super
      @constructor['testing removed'] ?= 0
      @constructor['testing removed']++

  QUnit.module 'CollectionView',
    setup: ->
      fakeENV.setup()
      collection = new Collection [
        {name: 'Jon', id: 24}
        {name: 'Ryan', id: 56}
      ]
      view = new CollectionView
        collection: collection
        emptyMessage: -> "No Results"
        itemView: ItemView
      view.$el.appendTo $('#fixtures')
      view.render()
    teardown: ->
      fakeENV.teardown()
      ItemView['testing removed'] = 0
      view.remove()

  # asserts match and order of rendered items
  assertRenderedItems = (names=[]) ->
    items = view.$list.children()
    equal items.length, names.length, 'items length matches'
    joinedItems = (el.innerHTML for el in items).join ' '
    joinedNames = names.join ' '
    joinedModels = collection.map((item) -> item.get('name')).join ' '
    equal joinedModels, joinedNames, 'collection order matches'
    equal joinedItems, joinedNames, 'dom order matches'

  assertItemRendered = (name) ->
    $match = view.$list.children().filter (i, el) -> el.innerHTML is name
    ok $match.length, 'item found'

  assertEmptyTemplateRendered = ->
    ok view.$el.text().match(/No Results/), 'empty template rendered'

  test 'renders added items', ->
    collection.reset()
    collection.add {name: 'Joe', id: 110}
    assertRenderedItems ['Joe']

  test 'renders empty template', ->
    collection.reset()
    assertRenderedItems()
    assertEmptyTemplateRendered()

  test 'renders empty template when last item is removed', ->
    collection.remove collection.get 24
    collection.remove collection.get 56
    assertRenderedItems()
    assertEmptyTemplateRendered()

  test 'removes empty template on add', ->
    collection.reset()
    assertEmptyTemplateRendered()
    collection.add {name: 'Joe', id: 110}
    ok !view.$el.text().match(/No Results/), 'empty template removed'
    assertItemRendered 'Joe'

  test 'removes items and re-renders on collection reset', ->
    collection.reset [{name: 'Joe', id: 110}]
    equal ItemView['testing removed'], 2
    assertRenderedItems ['Joe']

  test 'items are removed from view when removed from collection', ->
    collection.remove collection.get 24
    assertRenderedItems ['Ryan']

  test 'added items respect comparator', ->
    collection.add {name: 'Joe', id: 110}
    assertRenderedItems ['Joe', 'Ryan', 'Jon']
    collection.add {name: 'Cam', id: 106}
    assertRenderedItems ['Joe', 'Cam', 'Ryan', 'Jon']
    collection.add {name: 'Brian', id: 1}
    assertRenderedItems ['Joe', 'Cam', 'Ryan', 'Jon', 'Brian']

