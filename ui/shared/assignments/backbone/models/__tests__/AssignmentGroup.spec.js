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

import Assignment from '../Assignment'
import AssignmentGroup from '../AssignmentGroup'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('AssignmentGroup', () => {
  test('#hasRules returns true if group has regular rules', () => {
    const ag = new AssignmentGroup({rules: {drop_lowest: 1}})
    expect(ag.hasRules()).toBe(true)
  })

  test('#hasRules returns true if group has never drop rules', () => {
    const ag = new AssignmentGroup({
      assignments: {id: 1},
      rules: {never_drop: [1]},
    })
    expect(ag.hasRules()).toBe(true)
  })

  test('#hasRules returns false if the group has empty rules', () => {
    const ag = new AssignmentGroup({rules: {}})
    expect(ag.hasRules()).toBe(false)
  })

  test('#hasRules returns false if the group has no rules', () => {
    const ag = new AssignmentGroup()
    expect(ag.hasRules()).toBe(false)
  })

  test('#countRules works for regular rules', () => {
    const ag = new AssignmentGroup({rules: {drop_lowest: 1}})
    expect(ag.countRules()).toBe(1)
  })

  test('#countRules works for never drop rules', () => {
    const ag = new AssignmentGroup({
      assignments: {id: 1},
      rules: {never_drop: [1]},
    })
    expect(ag.countRules()).toBe(1)
  })

  test('#countRules only counts drop rules for assignments it has', () => {
    const ag = new AssignmentGroup({
      assignments: {id: 2},
      rules: {never_drop: [1]},
    })
    expect(ag.countRules()).toBe(0)
  })

  test('#countRules returns 0 if the group has empty rules', () => {
    const ag = new AssignmentGroup({rules: {}})
    expect(ag.countRules()).toBe(0)
  })

  test('#countRules returns 0 if the group has no rules', () => {
    const ag = new AssignmentGroup()
    expect(ag.countRules()).toBe(0)
  })

  test('#syncedWithSisCategory returns true if integration_data contains mapping', () => {
    const ag = new AssignmentGroup({integration_data: {sistemic: {categoryMapping: {abc: {}}}}})
    expect(ag.syncedWithSisCategory()).toBe(true)
  })

  test('#syncedWithSisCategory returns false if integration_data is empty', () => {
    const ag = new AssignmentGroup({integration_data: {}})
    expect(ag.syncedWithSisCategory()).toBe(false)
  })

  test('#syncedWithSisCategory returns false if integration_data is not set', () => {
    const ag = new AssignmentGroup()
    expect(ag.syncedWithSisCategory()).toBe(false)
  })

  test('#hasSisSourceId returns true if sis_source_id is not empty', () => {
    const ag = new AssignmentGroup({sis_source_id: '1234'})
    expect(ag.hasSisSourceId()).toBe(true)
  })

  test('#hasSisSourceId returns false if sis_source_id is empty', () => {
    const ag = new AssignmentGroup({sis_source_id: ''})
    expect(ag.hasSisSourceId()).toBe(false)
  })

  test('#hasSisSourceId returns false if sis_source_id is not set', () => {
    const ag = new AssignmentGroup()
    expect(ag.hasSisSourceId()).toBe(false)
  })
})

describe('AssignmentGroup#canDelete as admin', () => {
  beforeEach(() => {
    fakeENV.setup({current_user_is_admin: true})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test("returns true if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_grading_period' false", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', true)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    group.set('any_assignment_in_closed_grading_period', false)
    expect(group.canDelete()).toBe(true)
  })

  test("returns true if 'any_assignment_in_closed_grading_period' true and there are no frozen assignments", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', false)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [],
    })
    group.set('any_assignment_in_closed_grading_period', true)
    expect(group.canDelete()).toBe(true)
  })

  test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are true", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', true)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    group.set('any_assignment_in_closed_grading_period', true)
    expect(group.canDelete()).toBe(true)
  })

  test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', false)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    group.set('any_assignment_in_closed_grading_period', false)
    expect(group.canDelete()).toBe(true)
  })
})

describe('AssignmentGroup#canDelete as non admin', () => {
  beforeEach(() => {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test("returns false if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_grading_period is false", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', true)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    group.set('any_assignment_in_closed_grading_period', false)
    expect(group.canDelete()).toBe(false)
  })

  test("returns false if 'any_assignment_in_closed_grading_period' is true and there are no frozen assignments", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', false)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [],
    })
    group.set('any_assignment_in_closed_grading_period', true)
    expect(group.canDelete()).toBe(false)
  })

  test("returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', false)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    group.set('any_assignment_in_closed_grading_period', false)
    expect(group.canDelete()).toBe(true)
  })

  test("returns false if 'frozen' and 'any_assignment_in_closed_grading_period' are true", () => {
    const assignment = new Assignment({name: 'foo'})
    assignment.set('frozen', true)
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [],
    })
    group.set('any_assignment_in_closed_grading_period', true)
    expect(group.canDelete()).toBe(false)
  })
})

describe('AssignmentGroup#hasFrozenAssignments', () => {
  test('returns true if AssignmentGroup has frozen assignments', () => {
    const assignment = new Assignment({name: 'cheese'})
    assignment.set('frozen', [true])
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [assignment],
    })
    expect(group.hasFrozenAssignments()).toBe(true)
  })
})

describe('AssignmentGroup#anyAssignmentInClosedGradingPeriod', () => {
  test("returns the value of 'any_assignment_in_closed_grading_period'", () => {
    const group = new AssignmentGroup({
      name: 'taco',
      assignments: [],
    })
    group.set('any_assignment_in_closed_grading_period', true)
    expect(group.anyAssignmentInClosedGradingPeriod()).toBe(true)
    group.set('any_assignment_in_closed_grading_period', false)
    expect(group.anyAssignmentInClosedGradingPeriod()).toBe(false)
  })
})
