/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import cache from 'ui/features/assignment_index/cache'

QUnit.module('class/cache', {
  setup() {
    // need to get the cache from its wrapper object
    // because cache is meant to be used as a class
    // mixin
    this.cache = cache.cache
  },
})

test('should store strings', function () {
  this.cache.set('key', 'value')
  equal(this.cache.get('key'), 'value')
})

test('should store arrays and objects', function () {
  this.cache.set('array', [1, 2, 3])
  this.cache.set('object', {a: 1, b: 2})
  deepEqual(this.cache.get('array'), [1, 2, 3])
  deepEqual(this.cache.get('object'), {a: 1, b: 2})
})

test('should delete keys', function () {
  this.cache.set('key', 'value')
  this.cache.remove('key')
  equal(this.cache.get('key'), null)
})

test('should accept complex keys', function () {
  this.cache.set([1, 2, 3], 'value1')
  this.cache.set({a: 1, b: 1}, 'value2')
  this.cache.set([1, 2], {a: 1}, 'test', 'value3')

  equal(this.cache.get([1, 2, 3]), 'value1')
  equal(this.cache.get({a: 1, b: 1}), 'value2')
  equal(this.cache.get([1, 2], {a: 1}, 'test'), 'value3')
})

test('should accept a prefix', function () {
  this.cache.prefix = 'prefix-'
  this.cache.set('key', 'value')
  equal(typeof this.cache.store['prefix-"key"'], 'string')
})

test('should accept local and sessionStorage as stores', function () {
  this.cache.use('localStorage')
  equal(this.cache.store, localStorage)

  this.cache.use('sessionStorage')
  equal(this.cache.store, sessionStorage)

  // teardown for this test only
  this.cache.use('memory')
})
