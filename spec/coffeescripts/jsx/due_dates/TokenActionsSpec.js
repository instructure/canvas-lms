/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import TokenActions from '@canvas/due-dates/react/TokenActions'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import {map} from 'lodash'

QUnit.module('TokenActions is a thing', {
  setup() {
    this.assertValuesEqual = (override, keysAndVals) =>
      map(keysAndVals, (val, key) => deepEqual(override.get(key), val))
    this.assertTimesEqual = (override, keysAndVals) =>
      map(keysAndVals, (val, key) => deepEqual(override.get(key).getTime(), val.getTime()))
  },
})

test('new token with course section id is handled properly', function () {
  const initialOverrides = []
  const tokenToAdd = {type: 'section', course_section_id: 1}
  const newOverrides = TokenActions.handleTokenAdd(
    tokenToAdd,
    initialOverrides,
    1, // rowKey
    {due_at: new Date(2012, 1, 1)} // dates
  )
  this.assertTimesEqual(newOverrides[0], {due_at: new Date(2012, 1, 1)})
  this.assertValuesEqual(newOverrides[0], {course_section_id: 1, rowKey: 1})
})

test('new token with group id is handled properly', function () {
  const initialOverrides = []
  const tokenToAdd = {type: 'group', group_id: 1}
  const newOverrides = TokenActions.handleTokenAdd(
    tokenToAdd,
    initialOverrides,
    1, // rowKey
    {due_at: new Date(2012, 1, 1)} // dates
  )
  this.assertTimesEqual(newOverrides[0], {due_at: new Date(2012, 1, 1)})
  this.assertValuesEqual(newOverrides[0], {group_id: 1, rowKey: 1})
})

test('new token with student id is handled properly with no adhoc', function () {
  const initialOverrides = []
  const tokenToAdd = {type: 'student', id: 1}
  const newOverrides = TokenActions.handleTokenAdd(
    tokenToAdd,
    initialOverrides,
    1, // rowKey
    {due_at: new Date(2012, 1, 1)}
  )
  this.assertTimesEqual(newOverrides[0], {due_at: new Date(2012, 1, 1)})
  this.assertValuesEqual(newOverrides[0], {
    student_ids: [1],
    rowKey: 1,
  })
})

test('new token with student id is handled properly with an adhoc', function () {
  const attrs = {
    student_ids: [2],
    due_at: new Date(2012, 1, 1),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(attrs)]
  const tokenToAdd = {type: 'student', id: 1}
  const newOverrides = TokenActions.handleTokenAdd(
    tokenToAdd,
    initialOverrides,
    1, // rowKey
    {due_at: new Date(2012, 1, 1)}
  )
  this.assertTimesEqual(newOverrides[0], {due_at: new Date(2012, 1, 1)})
  this.assertValuesEqual(newOverrides[0], {student_ids: [2, 1], rowKey: 1})
})

test('override properties are properly copied', function () {
  const attrs = {
    student_ids: [1, 2],
    due_at: new Date(2012, 1, 1),
    lock_at: new Date(2012, 1, 5),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(attrs)]
  const tokenToAdd = {type: 'section', course_section_id: 1}
  const newOverrides = TokenActions.handleTokenAdd(
    tokenToAdd,
    initialOverrides,
    1, // rowKey
    {due_at: new Date(2012, 1, 1), lock_at: new Date(2012, 1, 5)} // dates
  )
  const sectionOverride = newOverrides.find(o => o.get('course_section_id'))
  this.assertTimesEqual(newOverrides[0], {
    due_at: new Date(2012, 1, 1),
    lock_at: new Date(2012, 1, 5),
  })
  this.assertValuesEqual(sectionOverride, {
    course_section_id: 1,
    rowKey: 1,
    due_at_overridden: true,
    lock_at_overridden: true,
    unlock_at_overridden: false,
  })
})

// ----------------------REMOVES------------------------------
test('removing token with course section id is handled properly', () => {
  const initialOverrideAttrs = {
    course_section_id: 2,
    due_at: new Date(2012, 1, 1),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
  const tokenToRemove = {type: 'section', course_section_id: 2}
  const newOverrides = TokenActions.handleTokenRemove(tokenToRemove, initialOverrides)
  deepEqual(newOverrides, [])
})

test('removing token with group id is handled properly', () => {
  const initialOverrideAttrs = {
    group_id: 2,
    due_at: new Date(2012, 1, 1),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
  const tokenToRemove = {type: 'section', group_id: 2}
  const newOverrides = TokenActions.handleTokenRemove(tokenToRemove, initialOverrides)
  deepEqual(newOverrides, [])
})

test('removing token with student id is handled properly when only student in adhoc', () => {
  const initialOverrideAttrs = {
    student_ids: [1],
    due_at: new Date(2012, 1, 1),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
  const tokenToRemove = {type: 'student', student_id: 1}
  const newOverrides = TokenActions.handleTokenRemove(tokenToRemove, initialOverrides)
  deepEqual(newOverrides, [])
})

test('removing token with student id is handled properly with other students in adhoc', function () {
  const initialOverrideAttrs = {
    student_ids: [1, 2],
    due_at: new Date(2012, 1, 1),
    rowKey: 1,
  }
  const initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
  const tokenToRemove = {type: 'student', student_id: 1}
  const newOverrides = TokenActions.handleTokenRemove(tokenToRemove, initialOverrides)

  this.assertTimesEqual(newOverrides[0], {due_at: new Date(2012, 1, 1)})
  this.assertValuesEqual(newOverrides[0], {student_ids: [2], rowKey: 1})
})
