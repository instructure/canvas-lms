/*
 * Copyright (C) 2013 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import Backbone from 'Backbone'
import SearchView from 'compiled/views/SearchView'
import InputFilterView from 'compiled/views/InputFilterView'
import CollectionView from 'compiled/views/CollectionView'
import 'helpers/jquery.simulate'

const view = null
let collection = null
let clock = null
let server = null
let searchView = null

class TestCollection extends Backbone.Collection {
  url = '/test'
}

class TestItemView extends Backbone.View {
  template({name}) {
    return name
  }
}

QUnit.module('SearchView', {
  setup() {
    collection = new TestCollection()
    const inputFilterView = new InputFilterView()
    const collectionView = new CollectionView({
      collection,
      itemView: TestItemView
    })
    searchView = new SearchView({
      inputFilterView,
      collectionView
    })
    searchView.$el.appendTo($('#fixtures'))
    searchView.render()
    clock = sinon.useFakeTimers()
    server = sinon.fakeServer.create()
    window.searchView = searchView
    window.collection = collection
  },
  teardown() {
    clock.restore()
    server.restore()
    searchView.remove()
    $('#fixtures').empty()
  }
})

// asserts match and order of rendered items
function assertRenderedItems(names = []) {
  const items = searchView.collectionView.$list.children()
  equal(items.length, names.length, 'items length matches')
  const joinedItems = Array.from(items).map(el => el.innerHTML).join(' ')
  const joinedNames = names.join(' ')
  const joinedModels = collection.map(item => item.get('name')).join(' ')
  equal(joinedModels, joinedNames, 'collection order matches')
  equal(joinedItems, joinedNames, 'dom order matches')
}

function setSearchTo(term) {
  searchView.inputFilterView.el.value = term
}

function simulateKeyup(opts = {}) {
  searchView.inputFilterView.$el.simulate('keyup', opts)
}

function sendResponse(url, json) {
  server.respond('GET', url, [200, {'Content-Type': 'application/json'}, JSON.stringify(json)])
}

function sendSearchResponse(json) {
  clock.tick(searchView.inputFilterView.options.onInputDelay)
  const search = searchView.inputFilterView.el.value
  const url = `${collection.url}?search_term=${search}`
  sendResponse(url, json)
}
test('renders results on input', () => {
  setSearchTo('ryan')
  simulateKeyup()
  sendSearchResponse([{name: 'ryanf'}, {name: 'ryanh'}])
  assertRenderedItems(['ryanf', 'ryanh'])
})

test('renders results on enter', () => {
  setSearchTo('ryan')
  simulateKeyup({keyCode: 13})
  sendSearchResponse([{name: 'ryanf'}, {name: 'ryanh'}])
  assertRenderedItems(['ryanf', 'ryanh'])
})

test('replaces old results', () => {
  setSearchTo('ryan')
  simulateKeyup()
  sendSearchResponse([{name: 'ryanf'}, {name: 'ryanh'}])
  assertRenderedItems(['ryanf', 'ryanh'])
  setSearchTo('jon')
  simulateKeyup()
  sendSearchResponse([{name: 'jon'}, {name: 'jonw'}])
  assertRenderedItems(['jon', 'jonw'])
})
