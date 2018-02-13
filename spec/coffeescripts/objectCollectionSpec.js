/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import objectCollection from 'compiled/util/objectCollection'

QUnit.module('objectCollection', {
  setup() {
    const arrayOfObjects = [
      {id: 1, name: 'foo'},
      {id: 2, name: 'bar'},
      {id: 3, name: 'baz'},
      {id: 4, name: 'quux'}
    ]
    this.collection = objectCollection(arrayOfObjects)
  }
})

test('indexOf', function() {
  const needle = this.collection[2]
  const index = this.collection.indexOf(needle)
  equal(index, 2, 'should find the correct index')
})

test('findBy', function() {
  const byId = this.collection.findBy('id', 1)
  equal(this.collection[0], byId, 'should find the first item by id')
  const byName = this.collection.findBy('name', 'bar')
  equal(this.collection[1], byName, 'should find the second item by name')
})

test('eraseBy', function() {
  const originalLength = this.collection.length
  equal(this.collection[0].id, 1, 'first item id should be 1')
  this.collection.eraseBy('id', 1)
  equal(this.collection.length, originalLength - 1, 'collection length should less by 1')
  equal(this.collection[0].id, 2, 'first item id should be 2, since first is erased')
})

test('insert', function() {
  const corge = {
    id: 5,
    name: 'corge'
  }
  this.collection.insert(corge)
  equal(this.collection[0], corge, 'should insert at index 0 by default')
  const grault = {
    id: 6,
    name: 'grault'
  }
  this.collection.insert(grault, 2)
  equal(this.collection[2], grault, 'should insert at an arbitrary index')
})

test('erase', function() {
  const originalLength = this.collection.length
  this.collection.erase(this.collection[0])
  equal(
    this.collection[0].name,
    'bar',
    'should erase first item by reference, second item becomes first'
  )
  equal(this.collection.length, originalLength - 1, 'should decrease length')
})

test('sortBy', function() {
  this.collection.sortBy('name')
  equal(this.collection[0].name, 'bar')
  equal(this.collection[1].name, 'baz')
  equal(this.collection[2].name, 'foo')
  equal(this.collection[3].name, 'quux')
  this.collection.sortBy('id')
  equal(this.collection[0].id, 1)
  equal(this.collection[1].id, 2)
  equal(this.collection[2].id, 3)
  equal(this.collection[3].id, 4)

  // case where length is zero
  this.collection.length = 0
  ok(this.collection.sortBy('id'))
})
