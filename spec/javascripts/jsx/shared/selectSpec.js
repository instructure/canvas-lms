/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import select from '@canvas/obj-select'

QUnit.module('Select function')

const obj = {
  id: '123',
  name: 'foo bar',
  points_possible: 30,
}

test('select individual properties', () => {
  deepEqual(select(obj, ['id', 'name']), {id: '123', name: 'foo bar'})
})

test('select and alias properties', () => {
  deepEqual(select(obj, ['id', ['points_possible', 'points']]), {id: '123', points: 30})
})
