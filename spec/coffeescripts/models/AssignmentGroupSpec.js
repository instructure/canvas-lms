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

import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import fakeENV from 'helpers/fakeENV'

QUnit.module('AssignmentGroup')

test('#hasRules returns true if group has regular rules', () => {
  const ag = new AssignmentGroup({rules: {drop_lowest: 1}})
  strictEqual(ag.hasRules(), true)
})

test('#hasRules returns true if group has never drop rules', () => {
  const ag = new AssignmentGroup({
    assignments: {id: 1},
    rules: {never_drop: [1]},
  })
  strictEqual(ag.hasRules(), true)
})

test('#hasRules returns false if the group has empty rules', () => {
  const ag = new AssignmentGroup({rules: {}})
  strictEqual(ag.hasRules(), false)
})

test('#hasRules returns false if the group has no rules', () => {
  const ag = new AssignmentGroup()
  strictEqual(ag.hasRules(), false)
})

test('#countRules works for regular rules', () => {
  const ag = new AssignmentGroup({rules: {drop_lowest: 1}})
  strictEqual(ag.countRules(), 1)
})

test('#countRules works for never drop rules', () => {
  const ag = new AssignmentGroup({
    assignments: {id: 1},
    rules: {never_drop: [1]},
  })
  strictEqual(ag.countRules(), 1)
})

test('#countRules only counts drop rules for assignments it has', () => {
  const ag = new AssignmentGroup({
    assignments: {id: 2},
    rules: {never_drop: [1]},
  })
  strictEqual(ag.countRules(), 0)
})

test('#countRules returns false if the group has empty rules', () => {
  const ag = new AssignmentGroup({rules: {}})
  strictEqual(ag.countRules(), 0)
})

test('#countRules returns false if the group has no rules', () => {
  const ag = new AssignmentGroup()
  strictEqual(ag.countRules(), 0)
})

test('#hasIntegrationData returns true if integration_data is not empty', () => {
  const ag = new AssignmentGroup({integration_data: {key: 'value'}})
  strictEqual(ag.hasIntegrationData(), true)
})

test('#hasIntegrationData returns false if integration_data is empty', () => {
  const ag = new AssignmentGroup({integration_data: {}})
  strictEqual(ag.hasIntegrationData(), false)
})

test('#hasIntegrationData returns false if integration_data is not set', () => {
  const ag = new AssignmentGroup()
  strictEqual(ag.hasIntegrationData(), false)
})

test('#hasIntegrationData returns true if sis_source_id is not empty', () => {
  const ag = new AssignmentGroup({sis_source_id: '1234'})
  strictEqual(ag.hasIntegrationData(), true)
})

test('#hasIntegrationData returns false if sis_source_id is empty', () => {
  const ag = new AssignmentGroup({sis_source_id: ''})
  strictEqual(ag.hasIntegrationData(), false)
})

test('#hasIntegrationData returns false if sis_source_id is not set', () => {
  const ag = new AssignmentGroup()
  strictEqual(ag.hasIntegrationData(), false)
})

test('#hasIntegrationData returns false if sis_source_id and integration_data is empty', () => {
  const ag = new AssignmentGroup({
    sis_source_id: '',
    integration_data: {},
  })
  strictEqual(ag.hasIntegrationData(), false)
})

QUnit.module('AssignmentGroup#canDelete as admin', {
  setup() {
    fakeENV.setup({current_user_is_admin: true})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns true if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_grading_period' false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  group.set('any_assignment_in_closed_grading_period', false)
  deepEqual(group.canDelete(), true)
})

test("returns true if 'any_assignment_in_closed_grading_period' true and there are no frozen assignments", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [],
  })
  group.set('any_assignment_in_closed_grading_period', true)
  equal(group.canDelete(), true)
})

test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  group.set('any_assignment_in_closed_grading_period', true)
  deepEqual(group.canDelete(), true)
})

test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  group.set('any_assignment_in_closed_grading_period', false)
  deepEqual(group.canDelete(), true)
})

QUnit.module('AssignmentGroup#canDelete as non admin', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns false if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_Grading_period is false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  group.set('any_assignment_in_closed_grading_period', false)
  deepEqual(group.canDelete(), false)
})

test("returns false if 'any_assignment_in_closed_grading_period' is true and there are no frozen assignments", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [],
  })
  group.set('any_assignment_in_closed_grading_period', true)
  equal(group.canDelete(), false)
})

test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  group.set('any_assignment_in_closed_grading_period', false)
  deepEqual(group.canDelete(), true)
})

test("returns false if 'frozen' and 'any_assignment_in_closed_grading_period' are true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [],
  })
  group.set('any_assignment_in_closed_grading_period', true)
  equal(group.canDelete(), false)
})

QUnit.module('AssignmentGroup#hasFrozenAssignments')

test('returns true if AssignmentGroup has frozen assignments', () => {
  const assignment = new Assignment({name: 'cheese'})
  assignment.set('frozen', [true])
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [assignment],
  })
  deepEqual(group.hasFrozenAssignments(), true)
})

QUnit.module('AssignmentGroup#anyAssignmentInClosedGradingPeriod')

test("returns the value of 'any_assignment_in_closed_grading_period'", () => {
  const group = new AssignmentGroup({
    name: 'taco',
    assignments: [],
  })
  group.set('any_assignment_in_closed_grading_period', true)
  deepEqual(group.anyAssignmentInClosedGradingPeriod(), true)
  group.set('any_assignment_in_closed_grading_period', false)
  deepEqual(group.anyAssignmentInClosedGradingPeriod(), false)
})
