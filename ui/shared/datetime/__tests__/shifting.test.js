/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {shift} from '../index'
import {moonwalk, setup} from './helpers'

setup(this)

test('shift() should add days', () => {
  expect(shift(moonwalk, '+1 days')).toEqual(new Date(+moonwalk + 86400000))
})

test('shift() should subtract days', () => {
  expect(shift(moonwalk, '-1 days')).toEqual(new Date(+moonwalk - 86400000))
})

test('shift() should add minutes', () => {
  expect(shift(moonwalk, '+1 minutes')).toEqual(new Date(+moonwalk + 60000))
})

test('shift() should subtract minutes', () => {
  expect(shift(moonwalk, '-1 minutes')).toEqual(new Date(+moonwalk - 60000))
})
