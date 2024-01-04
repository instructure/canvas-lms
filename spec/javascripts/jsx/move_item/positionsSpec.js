/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {positions, removeAllFromOrder} from '@canvas/positions'

QUnit.module('MoveItem positions')

test('removeAllFromOrder removes item if it is in order', () => {
  const order = ['a', 'b', 'c', 'd']
  const items = ['a']
  const expected = ['b', 'c', 'd']
  deepEqual(removeAllFromOrder(order, items), expected)
})

test('removeAllFromOrder does not change the order if item is not found', () => {
  const order = ['a', 'b', 'c', 'd']
  const items = ['z']
  deepEqual(removeAllFromOrder(order, items), order)
})

test('first places item first in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z']
  deepEqual(positions.first.apply({order, items}), ['z', 'a', 'b', 'c'])
})

test('last places item last in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z']
  deepEqual(positions.last.apply({order, items}), ['a', 'b', 'c', 'z'])
})

test('before places item correctly in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z']
  deepEqual(positions.before.apply({order, items, relativeTo: 1}), ['a', 'z', 'b', 'c'])
})

test('after places item correctly in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z']
  deepEqual(positions.after.apply({order, items, relativeTo: 1}), ['a', 'b', 'z', 'c'])
})

test('first places many items first in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z', 'q', 'h']
  deepEqual(positions.first.apply({order, items}), ['z', 'q', 'h', 'a', 'b', 'c'])
})

test('last places many items last in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z', 'q', 'h']
  deepEqual(positions.last.apply({order, items}), ['a', 'b', 'c', 'z', 'q', 'h'])
})

test('before places many items correctly in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z', 'q', 'h']
  deepEqual(positions.before.apply({order, items, relativeTo: 1}), ['a', 'z', 'q', 'h', 'b', 'c'])
})

test('after places many items correctly in order', () => {
  const order = ['a', 'b', 'c']
  const items = ['z', 'q', 'h']
  deepEqual(positions.after.apply({order, items, relativeTo: 1}), ['a', 'b', 'z', 'q', 'h', 'c'])
})
