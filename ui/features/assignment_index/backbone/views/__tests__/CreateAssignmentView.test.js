/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import CreateAssignmentView from '../CreateAssignmentView'
import $ from 'jquery'
import 'jquery-migrate'
import tzInTest from '@instructure/moment-utils/specHelpers'
import I18nStubber from '@canvas/test-utils/I18nStubber'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import '@canvas/common/activateTooltips'
import axe from 'axe-core'

function buildAssignment1() {
  const date1 = {
    due_at: new Date('2103-08-28T00:00:00').toISOString(),
    title: 'Summer Session',
  }
  const date2 = {
    due_at: new Date('2103-08-28T00:00:00').toISOString(),
    title: 'Winter Session',
  }
  return buildAssignment({
    id: 1,
    name: 'History Quiz',
    description: 'test',
    due_at: new Date('August 21, 2013').toISOString(),
    points_possible: 2,
    position: 1,
    all_dates: [date1, date2],
  })
}

const buildAssignment2 = () =>
  buildAssignment({
    id: 3,
    name: 'Math Quiz',
    due_at: new Date('August 23, 2013').toISOString(),
    points_possible: 10,
    position: 2,
  })

const buildAssignment3 = () =>
  buildAssignment({
    id: 4,
    name: '',
    due_at: '',
    points_possible: 10,
    position: 3,
  })

const buildAssignment4 = () =>
  buildAssignment({
    id: 5,
    name: '',
    due_at: '',
    unlock_at: new Date('August 1, 2013').toISOString(),
    lock_at: new Date('August 30, 2013').toISOString(),
    points_possible: 10,
    position: 4,
  })

const buildAssignment5 = () =>
  buildAssignment({
    id: 6,
    name: 'Page assignment',
    submission_types: ['wiki_page'],
    grading_type: 'not_graded',
    points_possible: null,
    position: 5,
  })

const buildAssignment = (options = {}) => ({
  assignment_group_id: 1,
  due_at: null,
  grading_type: 'points',
  points_possible: 5,
  position: 2,
  course_id: 1,
  name: 'Science Quiz',
  submission_types: [],
  html_url: `http://localhost:3000/courses/1/assignments/${options.id}`,
  needs_grading_count: 0,
  all_dates: [],
  published: true,
  ...options,
})

function assignmentGroup() {
  const assignments = [buildAssignment1(), buildAssignment2()]
  const group = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments,
  }
  const groups = new AssignmentGroupCollection([group])
  return groups.models[0]
}

function createView(model) {
  const opts = model.constructor === AssignmentGroup ? {assignmentGroup: model} : {model}
  const view = new CreateAssignmentView(opts)
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

function nameLengthHelper(view, length, maxNameLengthRequiredForAccount, maxNameLength, postToSis) {
  const name = 'a'.repeat(length)
  ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  ENV.MAX_NAME_LENGTH = maxNameLengthRequiredForAccount ? maxNameLength : 256 // Set to 256
  const data = {name, post_to_sis: !!postToSis, grading_type: view.model.get('grading_type')} // Always include grading_type

  return view.validateBeforeSave(data, [])
}

describe('CreateAssignmentView', () => {
  let assignment1, assignment2, assignment3, assignment4, assignment5, group
  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    assignment1 = new Assignment(buildAssignment1())
    assignment2 = new Assignment(buildAssignment2())
    assignment3 = new Assignment(buildAssignment3())
    assignment4 = new Assignment(buildAssignment4())
    assignment5 = new Assignment(buildAssignment5())
    group = assignmentGroup()
    I18nStubber.pushFrame()
    fakeENV.setup({
      SETTINGS: {},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    tzInTest.restore()
    I18nStubber.clear()
    fixtures.remove()
  })

  it('should be accessible', async () => {
    const view = createView(assignment1)
    const results = await axe.run(view.$el[0])
    expect(results.violations).toHaveLength(0)
  })

  it('generates a new assignment for creation', () => {
    const view = createView(group)
    expect(view.model.get('assignment_group_id')).toBe(group.get('id'))
  })

  it('uses existing assignment for editing', () => {
    const view = createView(assignment1)
    expect(view.model.get('name')).toBe(assignment1.get('name'))
  })

  it('shows multipleDueDates if we have all dates', () => {
    const view = createView(assignment1)
    expect(view.$('.multiple_due_dates')).toHaveLength(1)
  })

  it('shows date picker when there are not multipleDueDates', () => {
    const view = createView(assignment2)
    expect(view.$('.multiple_due_dates')).toHaveLength(0)
  })

  it('shows canChooseType for creation', () => {
    const view = createView(group)
    expect(view.$('#ag_1_assignment_type')).toHaveLength(1)
    expect(view.$('#assign_1_assignment_type')).toHaveLength(0)
  })

  it('hides canChooseType for editing', () => {
    const view = createView(assignment1)
    expect(view.$('#ag_1_assignment_type')).toHaveLength(0)
    expect(view.$('#assign_1_assignment_type')).toHaveLength(0)
  })

  it('hides date picker and points_possible for pages', () => {
    const view = createView(assignment5)
    expect(view.$('#assignment_due_date_controls')).toHaveLength(0)
    expect(view.$('#assignment_points_possible')).toHaveLength(0)
  })

  describe('name length validation', () => {
    it('allows assignment to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', () => {
      const view = createView(assignment3)
      const errors = nameLengthHelper(view, 256, false, 30, true)
      expect(errors.name).toBeFalsy()
    })

    it('allows assignment to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', () => {
      assignment3.grading_type = 'not_graded'
      const view = createView(assignment3)
      const errors = nameLengthHelper(view, 15, true, 10, true)
      expect(errors.name).toBeFalsy()
    })

    it("doesn't validate name if it is frozen", () => {
      const view = createView(assignment3)
      assignment3.set('frozen_attributes', ['title'])
      const errors = view.validateBeforeSave({}, [])
      expect(errors.name).toBeFalsy()
    })
  })
})
