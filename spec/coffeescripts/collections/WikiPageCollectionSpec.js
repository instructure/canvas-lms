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

import WikiPage from 'compiled/models/WikiPage'
import WikiPageCollection from 'compiled/collections/WikiPageCollection'

QUnit.module('WikiPageCollection')
const checkFrontPage = function(collection) {
  const total = collection.reduce((i, model) => (i += model.get('front_page') ? 1 : 0), 0)
  return total <= 1
}
test('only a single front_page per collection', () => {
  const collection = new WikiPageCollection()
  for (let i = 0; i <= 2; i++) {
    collection.add(new WikiPage())
  }
  ok(checkFrontPage(collection), 'initial state')
  collection.models[0].set('front_page', true)
  ok(checkFrontPage(collection), 'set front_page once')
  collection.models[1].set('front_page', true)
  ok(checkFrontPage(collection), 'set front_page twice')
  collection.models[2].set('front_page', true)
  ok(checkFrontPage(collection), 'set front_page thrice')
})

QUnit.module('WikiPageCollection:sorting', {
  setup() {
    this.collection = new WikiPageCollection()
  }
})

test('default sort is title', function() {
  equal(this.collection.currentSortField, 'title', 'default sort set correctly')
})

test('default sort orders', function() {
  equal(this.collection.sortOrders.title, 'asc', 'default title sort order')
  equal(this.collection.sortOrders.created_at, 'desc', 'default created_at sort order')
  equal(this.collection.sortOrders.updated_at, 'desc', 'default updated_at sort order')
})

test('sort order toggles (sort on same field)', function() {
  this.collection.currentSortField = 'created_at'
  this.collection.sortOrders.created_at = 'desc'
  this.collection.setSortField('created_at')
  equal(this.collection.sortOrders.created_at, 'asc', 'sort order toggled')
})

test('sort order does not toggle (sort on different field)', function() {
  this.collection.currentSortField = 'title'
  this.collection.sortOrders.created_at = 'desc'
  this.collection.setSortField('created_at')
  equal(this.collection.sortOrders.created_at, 'desc', 'sort order remains')
})

test('sort order can be forced', function() {
  this.collection.currentSortField = 'title'
  this.collection.setSortField('created_at', 'asc')
  equal(this.collection.currentSortField, 'created_at', 'sort field set')
  equal(this.collection.sortOrders.created_at, 'asc', 'sort order forced')
  this.collection.setSortField('created_at', 'asc')
  equal(this.collection.currentSortField, 'created_at', 'sort field remains')
  equal(this.collection.sortOrders.created_at, 'asc', 'sort order remains')
})

test('setting sort triggers a sortChanged event', function() {
  const sortChangedSpy = sinon.spy()
  this.collection.on('sortChanged', sortChangedSpy)
  this.collection.setSortField('created_at')
  ok(sortChangedSpy.calledOnce, 'sortChanged event triggered once')
  ok(
    sortChangedSpy.calledWith(this.collection.currentSortField, this.collection.sortOrders),
    'sortChanged triggered with parameters'
  )
})

test('setting sort sets fetch parameters', function() {
  this.collection.setSortField('created_at', 'desc')
  ok(this.collection.options, 'options exists')
  ok(this.collection.options.params, 'params exists')
  equal(this.collection.options.params.sort, 'created_at', 'sort param set')
  equal(this.collection.options.params.order, 'desc', 'order param set')
})

test('sortByField delegates to setSortField', function() {
  const setSortFieldStub = sandbox.stub(this.collection, 'setSortField')
  const fetchStub = sandbox.stub(this.collection, 'fetch')
  this.collection.sortByField('created_at', 'desc')
  ok(setSortFieldStub.calledOnce, 'setSortField called once')
  ok(
    setSortFieldStub.calledWith('created_at', 'desc'),
    'setSortField called with correct arguments'
  )
})

test('sortByField triggers a fetch', function() {
  const fetchStub = sandbox.stub(this.collection, 'fetch')
  this.collection.sortByField('created_at', 'desc')
  ok(fetchStub.calledOnce, 'fetch called once')
})
