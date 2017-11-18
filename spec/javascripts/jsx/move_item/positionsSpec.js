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

import { positions, removeFromOrder } from 'jsx/move_item/positions'

QUnit.module('MoveItem positions')

test('removeFromOrder removes item if it is in order', () => {
  const order = ['a', 'b', 'c', 'd']
  const item = 'a'
  const expected = ['b', 'c', 'd']
  deepEqual(removeFromOrder(order, item), expected)
})

test('removeFromOrder does not change the order if item is not found', () => {
  const order = ['a', 'b', 'c', 'd']
  const item = 'z'
  deepEqual(removeFromOrder(order, item), order)
})

test('first places item first in order', () => {
  const order = ['a', 'b', 'c']
  const item = 'z'
  deepEqual(positions.first.apply({ order, item }), ['z', 'a', 'b', 'c'])
})

test('last places item last in order', () => {
  const order = ['a', 'b', 'c']
  const item = 'z'
  deepEqual(positions.last.apply({ order, item }), ['a', 'b', 'c', 'z'])
})

test('before places item correctly in order', () => {
  const order = ['a', 'b', 'c']
  const item = 'z'
  deepEqual(positions.before.apply({ order, item, relativeTo: 1 }), ['a', 'z', 'b', 'c'])
})

test('after places item correctly in order', () => {
  const order = ['a', 'b', 'c']
  const item = 'z'
  deepEqual(positions.after.apply({ order, item, relativeTo: 1 }), ['a', 'b', 'z', 'c'])
})