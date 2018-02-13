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

import _ from 'underscore'
import assignmentHelper from 'jsx/gradebook/shared/helpers/assignmentHelper'

QUnit.module('assignmentHelper#getComparator', {
  setup() {},
  teardown() {}
})

test('returns the correct function when passed "due_date"', () => {
  const expectedFn = assignmentHelper.compareByDueDate
  const returnedFn = assignmentHelper.getComparator('due_date')
  return propEqual(returnedFn, expectedFn)
})

test('returns the correct function when passed "assignment_group"', () => {
  const expectedFn = assignmentHelper.compareByAssignmentGroup
  const returnedFn = assignmentHelper.getComparator('assignment_group')
  return propEqual(returnedFn, expectedFn)
})

QUnit.module('assignmentHelper#compareByDueDate', {
  setup() {},
  teardown() {}
})
const generateAssignment = function(options) {
  options = options || {}
  return _.defaults(options, {
    name: 'assignment',
    due_at: new Date('Mon May 11 2015'),
    effectiveDueDates: {}
  })
}
const generateEffectiveDueDates = () => ({
  '1': {due_at: 'Mon May 11 2015'},
  '2': {due_at: 'Tue May 12 2015'}
})

test('compares assignments by due date', () => {
  const assignment1 = generateAssignment()
  const assignment2 = generateAssignment({due_at: new Date('Tue May 12 2015')})
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
  assignment1.due_at = new Date('Wed May 13 2015')
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
})

test('treats null values as "greater" than Date values', () => {
  const assignment1 = generateAssignment({due_at: null})
  const assignment2 = generateAssignment()
  const comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
})

test('compares by name if dates are the same', () => {
  const assignment1 = generateAssignment({name: 'Banana'})
  const assignment2 = generateAssignment({name: 'Apple'})
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
  assignment2.name = 'Carrot'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
})

test('ignores case when comparing by name', () => {
  const assignment1 = generateAssignment({name: 'Banana'})
  const assignment2 = generateAssignment({name: 'apple'})
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
  assignment2.name = 'Apple'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
})

test('compares by due date overrides if dates are both null', () => {
  const assignment1 = generateAssignment({due_at: null})
  assignment1.effectiveDueDates = generateEffectiveDueDates()
  const assignment2 = generateAssignment({due_at: null})
  const comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
})

test('hasMultipleDueDates returns false when provided an empty object', () => {
  const assignment = {}
  notOk(assignmentHelper.hasMultipleDueDates(assignment))
})

test('hasMultipleDueDates returns false when there is only 1 unique effective due date', () => {
  const assignment = generateAssignment({due_at: null})
  assignment.effectiveDueDates = {'1': {due_at: 'Mon May 11 2015'}}
  notOk(assignmentHelper.hasMultipleDueDates(assignment))
})

test('hasMultipleDueDates returns true when provided overrides with a length greater than 1', () => {
  const assignment = generateAssignment({due_at: null})
  assignment.effectiveDueDates = generateEffectiveDueDates()
  ok(assignmentHelper.hasMultipleDueDates(assignment))
})

test(
  'treats assignments with a single override with a null date as' +
    '"greater" than assignments with multiple overrides',
  () => {
    const assignment1 = generateAssignment({due_at: null})
    assignment1.effectiveDueDates = {'1': {due_at: null}}
    const assignment2 = generateAssignment({due_at: null})
    assignment2.effectiveDueDates = {
      '1': {due_at: null},
      '2': {due_at: 'Mon May 11 2015'}
    }
    const comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok(comparisonVal > 0)
  }
)

test('compares by name if dates are both null and both have multiple overrides', () => {
  const assignment1 = {
    name: 'Banana',
    due_at: null
  }
  assignment1.effectiveDueDates = {
    '1': {due_at: null},
    '2': {due_at: 'Mon May 11 2015'}
  }
  const assignment2 = {
    name: 'Apple',
    due_at: null
  }
  assignment2.effectiveDueDates = {
    '1': {due_at: null},
    '2': {due_at: 'Mon May 11 2015'}
  }
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
  assignment2.name = 'Carrot'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
})

test('compares by name if dates are both null and neither have due date overrides', () => {
  const assignment1 = {
    name: 'Banana',
    due_at: null
  }
  const assignment2 = {
    name: 'Apple',
    due_at: null
  }
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
  assignment2.name = 'Carrot'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
})

test('treats assignments with the same dates and names as equal', () => {
  const assignment1 = generateAssignment()
  const assignment2 = generateAssignment()
  const comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal === 0)
})

test('handles one due_at passed in as string and another passed in as date', () => {
  const assignment1 = generateAssignment()
  const assignment2 = generateAssignment({due_at: '2015-05-20T06:59:00Z'})
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
  assignment2.due_at = '2015-05-05T06:59:00Z'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
})

test('handles both due_ats passed in as strings', () => {
  const assignment1 = generateAssignment({due_at: '2015-05-11T06:59:00Z'})
  const assignment2 = generateAssignment({due_at: '2015-05-20T06:59:00Z'})
  let comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal < 0)
  assignment2.due_at = '2015-05-05T06:59:00Z'
  comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
  ok(comparisonVal > 0)
})

QUnit.module('assignmentHelper#compareByAssignmentGroup', {
  setup() {},
  teardown() {}
})

test('compares assignments by their assignment group position', () => {
  const assignment1 = {
    assignment_group_position: 1,
    position: 1
  }
  const assignment2 = {
    assignment_group_position: 2,
    position: 1
  }
  let comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
  ok(comparisonVal < 0)
  assignment1.assignment_group_position = 3
  comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
  ok(comparisonVal > 0)
})

test('compares by assignment position if assignment group position is the same', () => {
  const assignment1 = {
    assignment_group_position: 1,
    position: 2
  }
  const assignment2 = {
    assignment_group_position: 1,
    position: 1
  }
  let comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
  ok(comparisonVal > 0)
  assignment2.position = 3
  comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
  ok(comparisonVal < 0)
})

test('treats assignments with the same position and group position as equal', () => {
  const assignment1 = {
    assignment_group_position: 1,
    position: 1
  }
  const assignment2 = {
    assignment_group_position: 1,
    position: 1
  }
  const comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
  ok(comparisonVal === 0)
})
