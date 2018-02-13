#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  'compiled/views/SearchView'
  'compiled/views/InputFilterView'
  'compiled/views/CollectionView'
  'helpers/jquery.simulate'
], ($, Backbone, SearchView, InputFilterView, CollectionView) ->

  view = null
  collection = null
  clock = null
  server = null
  searchView = null

  class TestCollection extends Backbone.Collection
    url: '/test'

  class TestItemView extends Backbone.View
    template: ({name}) -> name

  QUnit.module 'SearchView',
    setup: ->
      collection = new TestCollection
      inputFilterView = new InputFilterView
      collectionView = new CollectionView
        collection: collection
        itemView: TestItemView
      searchView = new SearchView
        inputFilterView: inputFilterView
        collectionView: collectionView
      searchView.$el.appendTo $('#fixtures')
      searchView.render()
      clock = sinon.useFakeTimers()
      server = sinon.fakeServer.create()
      window.searchView = searchView
      window.collection = collection
    teardown: ->
      clock.restore()
      server.restore()
      searchView.remove()
      $("#fixtures").empty()

  # asserts match and order of rendered items
  assertRenderedItems = (names=[]) ->
    items = searchView.collectionView.$list.children()
    equal items.length, names.length, 'items length matches'
    joinedItems = (el.innerHTML for el in items).join ' '
    joinedNames = names.join ' '
    joinedModels = collection.map((item) -> item.get('name')).join ' '
    equal joinedModels, joinedNames, 'collection order matches'
    equal joinedItems, joinedNames, 'dom order matches'

  setSearchTo = (term) ->
    searchView.inputFilterView.el.value = term

  simulateKeyup = (opts={}) ->
    searchView.inputFilterView.$el.simulate 'keyup', opts

  sendResponse = (url, json) ->
    server.respond 'GET', url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(json)]

  sendSearchResponse = (json) ->
    clock.tick searchView.inputFilterView.options.onInputDelay
    search = searchView.inputFilterView.el.value
    url = "#{collection.url}?search_term=#{search}"
    sendResponse url, json

  test 'renders results on input', ->
    setSearchTo 'ryan'
    simulateKeyup()
    sendSearchResponse [{name: 'ryanf'}, {name: 'ryanh'}]
    assertRenderedItems ['ryanf', 'ryanh']

  test 'renders results on enter', ->
    setSearchTo 'ryan'
    simulateKeyup keyCode: 13
    sendSearchResponse [{name: 'ryanf'}, {name: 'ryanh'}]
    assertRenderedItems ['ryanf', 'ryanh']

  test 'replaces old results', ->
    setSearchTo 'ryan'
    simulateKeyup()
    sendSearchResponse [{name: 'ryanf'}, {name: 'ryanh'}]
    assertRenderedItems ['ryanf', 'ryanh']
    setSearchTo 'jon'
    simulateKeyup()
    sendSearchResponse [{name: 'jon'}, {name: 'jonw'}]
    assertRenderedItems ['jon', 'jonw']

