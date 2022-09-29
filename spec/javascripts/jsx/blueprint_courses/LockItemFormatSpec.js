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

import {formatLockObject, formatLockArray} from '@canvas/blueprint-courses/react/LockItemFormat'

QUnit.module('LockItemFormat functions')

test('takes in multiple items and returns a formatted string', () => {
  const lockArray = ['content', 'due_dates']
  const formattedString = formatLockArray(lockArray)
  deepEqual(formattedString, 'Content & Due Dates')
})

test('takes in no items and returns "no locks" message', () => {
  const lockArray = []
  const formattedString = formatLockArray(lockArray)
  deepEqual(formattedString, 'no attributes locked')
})

test('takes in an object with all items false and returns "no locks" message', () => {
  const lockObject = {
    content: false,
    points: false,
    due_dates: false,
    availability_dates: false,
  }
  const formattedString = formatLockObject(lockObject)
  deepEqual(formattedString, 'no attributes locked')
})

test('takes in an object with multiple items and returns a formatted string', () => {
  const lockObject = {
    content: true,
    points: true,
    due_dates: false,
    availability_dates: true,
  }
  const formattedString = formatLockObject(lockObject)
  deepEqual(formattedString, 'Content, Points & Availability Dates')
})
