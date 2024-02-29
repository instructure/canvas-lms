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
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import fakeENV from 'helpers/fakeENV'

let collection = null
let view = null

class Collection extends Backbone.Collection {
  static initClass() {
    this.prototype.model = Backbone.Model
  }

  comparator(a, b) {
    if (a.get('id') < b.get('id')) {
      return 1
    } else {
      return -1
    }
  }
}
Collection.initClass()

class ItemView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'li'
  }

  template({name}) {
    return name
  }

  remove() {
    super.remove(...arguments)
    if (this.constructor['testing removed'] == null) {
      this.constructor['testing removed'] = 0
    }
    return this.constructor['testing removed']++
  }
}
ItemView.initClass()

QUnit.module('CollectionView', {
  setup() {
    fakeENV.setup()
    collection = new Collection([
      {name: 'Jon', id: 24},
      {name: 'Ryan', id: 56},
    ])
    view = new CollectionView({
      collection,
      emptyMessage() {
        return 'No Results'
      },
      itemView: ItemView,
    })
    view.$el.appendTo($('#fixtures'))
    view.render()
  },
  teardown() {
    fakeENV.teardown()
    ItemView['testing removed'] = 0
    view.remove()
  },
})

// asserts match and order of rendered items
function assertRenderedItems(names = []) {
  const items = view.$list.children()
  equal(items.length, names.length, 'items length matches')
  const joinedItems = Array.from(items)
    .map(el => el.innerHTML)
    .join(' ')
  const joinedNames = names.join(' ')
  const joinedModels = collection.map(item => item.get('name')).join(' ')
  equal(joinedModels, joinedNames, 'collection order matches')
  equal(joinedItems, joinedNames, 'dom order matches')
}

function assertItemRendered(name) {
  const $match = view.$list.children().filter((i, el) => el.innerHTML === name)
  ok($match.length, 'item found')
}

function assertEmptyTemplateRendered() {
  ok(view.$el.text().match(/No Results/), 'empty template rendered')
}

test('renders added items', () => {
  collection.reset()
  collection.add({name: 'Joe', id: 110})
  assertRenderedItems(['Joe'])
})

test('renders empty template', () => {
  collection.reset()
  assertRenderedItems()
  assertEmptyTemplateRendered()
})

test('renders empty template when last item is removed', () => {
  collection.remove(collection.get(24))
  collection.remove(collection.get(56))
  assertRenderedItems()
  assertEmptyTemplateRendered()
})

test('removes empty template on add', () => {
  collection.reset()
  assertEmptyTemplateRendered()
  collection.add({name: 'Joe', id: 110})
  ok(!view.$el.text().match(/No Results/), 'empty template removed')
  assertItemRendered('Joe')
})

test('removes items and re-renders on collection reset', () => {
  collection.reset([{name: 'Joe', id: 110}])
  equal(ItemView['testing removed'], 2)
  assertRenderedItems(['Joe'])
})

test('items are removed from view when removed from collection', () => {
  collection.remove(collection.get(24))
  assertRenderedItems(['Ryan'])
})

test('added items respect comparator', () => {
  collection.add({name: 'Joe', id: 110})
  assertRenderedItems(['Joe', 'Ryan', 'Jon'])
  collection.add({name: 'Cam', id: 106})
  assertRenderedItems(['Joe', 'Cam', 'Ryan', 'Jon'])
  collection.add({name: 'Brian', id: 1})
  assertRenderedItems(['Joe', 'Cam', 'Ryan', 'Jon', 'Brian'])
})
