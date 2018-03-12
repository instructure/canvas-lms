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

import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Assignment from 'compiled/models/Assignment'
import CreateAssignmentView from 'compiled/views/assignments/CreateAssignmentView'
import DialogFormView from 'compiled/views/DialogFormView'
import $ from 'jquery'
import tz from 'timezone'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'
import 'compiled/behaviors/tooltip'

const fixtures = $('#fixtures')

function buildAssignment1() {
  const date1 = {
    due_at: new Date('2103-08-28T00:00:00').toISOString(),
    title: 'Summer Session'
  }
  const date2 = {
    due_at: new Date('2103-08-28T00:00:00').toISOString(),
    title: 'Winter Session'
  }
  return buildAssignment({
    id: 1,
    name: 'History Quiz',
    description: 'test',
    due_at: new Date('August 21, 2013').toISOString(),
    points_possible: 2,
    position: 1,
    all_dates: [date1, date2]
  })
}

const buildAssignment2 = () =>
  buildAssignment({
    id: 3,
    name: 'Math Quiz',
    due_at: new Date('August 23, 2013').toISOString(),
    points_possible: 10,
    position: 2
  })

const buildAssignment3 = () =>
  buildAssignment({
    id: 4,
    name: '',
    due_at: '',
    points_possible: 10,
    position: 3
  })

const buildAssignment4 = () =>
  buildAssignment({
    id: 5,
    name: '',
    due_at: '',
    unlock_at: new Date('August 1, 2013').toISOString(),
    lock_at: new Date('August 30, 2013').toISOString(),
    points_possible: 10,
    position: 4
  })

const buildAssignment5 = () =>
  buildAssignment({
    id: 6,
    name: 'Page assignment',
    submission_types: ['wiki_page'],
    grading_type: 'not_graded',
    points_possible: null,
    position: 5
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
  ...options
})

function assignmentGroup() {
  const assignments = [buildAssignment1(), buildAssignment2()]
  const group = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments
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
  ENV.MAX_NAME_LENGTH = maxNameLength
  return view.validateBeforeSave({name, post_to_sis: postToSis}, [])
}

QUnit.module('CreateAssignmentView', {
  setup() {
    this.assignment1 = new Assignment(buildAssignment1())
    this.assignment2 = new Assignment(buildAssignment2())
    this.assignment3 = new Assignment(buildAssignment3())
    this.assignment4 = new Assignment(buildAssignment4())
    this.assignment5 = new Assignment(buildAssignment5())
    this.group = assignmentGroup()
    this.snapshot = tz.snapshot()
    I18nStubber.pushFrame()
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
    tz.restore(this.snapshot)
    I18nStubber.popFrame()
  }
})

test('should be accessible', function(assert) {
  const view = createView(this.assignment1)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('initialize generates a new assignment for creation', function() {
  const view = createView(this.group)
  equal(view.model.get('assignment_group_id'), this.group.get('id'))
})

test('initialize uses existing assignment for editing', function() {
  const view = createView(this.assignment1)
  equal(view.model.get('name'), this.assignment1.get('name'))
})

test('render shows multipleDueDates if we have all dates', function() {
  const view = createView(this.assignment1)
  equal(view.$('.multiple_due_dates').length, 1)
})

test('render shows date picker when there are not multipleDueDates', function() {
  const view = createView(this.assignment2)
  equal(view.$('.multiple_due_dates').length, 0)
})

test('render shows canChooseType for creation', function() {
  const view = createView(this.group)
  equal(view.$('#ag_1_assignment_type').length, 1)
  equal(view.$('#assign_1_assignment_type').length, 0)
})

test('render hides canChooseType for editing', function() {
  const view = createView(this.assignment1)
  equal(view.$('#ag_1_assignment_type').length, 0)
  equal(view.$('#assign_1_assignment_type').length, 0)
})

test('render hides date picker and points_possible for pages', function() {
  const view = createView(this.assignment5)
  equal(view.$('.date_field_container').length, 0)
  equal(view.$('input[name=points_possible]').length, 0)
})

test('onSaveSuccess adds model to assignment group for creation', function() {
  this.stub(DialogFormView.prototype, 'close')
  equal(this.group.get('assignments').length, 2)
  const view = createView(this.group)
  view.onSaveSuccess()
  equal(this.group.get('assignments').length, 3)
})

test('the form is cleared after adding an assignment', function() {
  this.stub(DialogFormView.prototype, 'close')
  const view = createView(this.group)
  view.onSaveSuccess()
  equal(view.$(`#ag_${this.group.id}_assignment_name`).val(), '')
  equal(view.$(`#ag_${this.group.id}_assignment_points`).val(), '0')
})

test('moreOptions redirects to new page for creation', function() {
  this.stub(CreateAssignmentView.prototype, 'newAssignmentUrl')
  this.stub(CreateAssignmentView.prototype, 'redirectTo')
  const view = createView(this.group)
  view.moreOptions()
  ok(view.redirectTo.called)
})

test('moreOptions redirects to edit page for editing', function() {
  this.stub(CreateAssignmentView.prototype, 'redirectTo')
  const view = createView(this.assignment1)
  view.moreOptions()
  ok(view.redirectTo.called)
})

test('moreOptions creates a quiz if submission_types is online_quiz', function() {
  const newQuizUrl = 'http://example.com/course/1/quizzes/new'
  const formData = {submission_types: 'online_quiz'}
  this.stub(CreateAssignmentView.prototype, 'getFormData').returns(formData)
  this.stub(CreateAssignmentView.prototype, 'newQuizUrl').returns(newQuizUrl)
  this.stub(CreateAssignmentView.prototype, 'redirectTo')
  const quizEditUrl = 'http://example.com/course/1/quizzes/42/edit'
  this.stub($, 'post').returns($.Deferred().resolve({url: quizEditUrl}))
  const view = createView(this.assignment1)
  view.moreOptions()
  ok($.post.calledWith(newQuizUrl, formData))
  ok(view.redirectTo.calledWith(quizEditUrl))
})

test('generateNewAssignment builds new assignment model', function() {
  const view = createView(this.group)
  const assign = view.generateNewAssignment()
  ok(assign.constructor === Assignment)
})

test('toJSON creates unique label for creation', function() {
  const view = createView(this.group)
  const json = view.toJSON()
  equal(json.uniqLabel, 'ag_1')
})

test('toJSON creates unique label for editing', function() {
  const view = createView(this.assignment1)
  const json = view.toJSON()
  equal(json.uniqLabel, 'assign_1')
})

test('toJSON includes can choose type when creating', function() {
  const view = createView(this.group)
  const json = view.toJSON()
  ok(json.canChooseType)
})

test('toJSON includes cannot choose type when creating', function() {
  const view = createView(this.assignment1)
  const json = view.toJSON()
  ok(!json.canChooseType)
})

test('toJSON includes key for disableDueAt', function() {
  const view = createView(this.assignment1)
  ok('disableDueAt' in view.toJSON())
})

test('toJSON includes key for isInClosedPeriod', function() {
  const view = createView(this.assignment1)
  ok('isInClosedPeriod' in view.toJSON())
})

test('disableDueAt returns true if due_at is a frozen attribute', function() {
  const view = createView(this.assignment1)
  this.stub(view.model, 'frozenAttributes').returns(['due_at'])
  equal(view.disableDueAt(), true)
})

test('disableDueAt returns false if the user is an admin', function() {
  const view = createView(this.assignment1)
  this.stub(view, 'currentUserIsAdmin').returns(true)
  equal(view.disableDueAt(), false)
})

test('disableDueAt returns true if the user is not an admin and the assignment has a due date in a closed grading period', function() {
  const view = createView(this.assignment1)
  this.stub(view, 'currentUserIsAdmin').returns(false)
  this.stub(view.model, 'inClosedGradingPeriod').returns(true)
  equal(view.disableDueAt(), true)
})

test("openAgain doesn't add datetime for multiple dates", function() {
  this.stub(DialogFormView.prototype, 'openAgain')
  this.spy($.fn, 'datetime_field')
  const view = createView(this.assignment1)
  view.openAgain()
  ok($.fn.datetime_field.notCalled)
})

test('openAgain adds datetime picker', function() {
  this.stub(DialogFormView.prototype, 'openAgain')
  this.spy($.fn, 'datetime_field')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.medium': '%a %-d %b %Y %-k:%M',
    'date.month_names': ['août'],
    'date.abbr_month_names': ['août']
  })
  const view = createView(this.assignment2)
  view.openAgain()
  ok($.fn.datetime_field.called)
})

test("openAgain doesn't add datetime picker if disableDueAt is true", function() {
  this.stub(DialogFormView.prototype, 'openAgain')
  this.spy($.fn, 'datetime_field')
  const view = createView(this.assignment2)
  this.stub(view, 'disableDueAt').returns(true)
  view.openAgain()
  ok($.fn.datetime_field.notCalled)
})

test('requires name to save assignment', function() {
  const view = createView(this.assignment3)
  const data = {name: ''}
  const errors = view.validateBeforeSave(data, [])
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is required!')
})

test('requires due_at to be in an open grading period if it is being changed and the user is a teacher', function() {
  ENV.HAS_GRADING_PERIODS = true
  ENV.active_grading_periods = [
    {
      id: '1',
      start_date: '2103-07-01T06:00:00Z',
      end_date: '2103-08-31T06:00:00Z',
      title: 'Closed Period',
      close_date: '2103-08-31T06:00:00Z',
      is_last: false,
      is_closed: true
    }
  ]
  const view = createView(this.assignment1)
  this.stub(view, 'currentUserIsAdmin').returns(false)
  const data = {
    name: 'Foo',
    due_at: '2103-08-15T06:00:00Z'
  }
  const errors = view.validateBeforeSave(data, [])
  equal(errors.due_at[0].message, 'Due date cannot fall in a closed grading period')
})

test('does not require due_at to be in an open grading period if it is being changed and the user is an admin', function() {
  ENV.active_grading_periods = [
    {
      id: '1',
      start_date: '2103-07-01T06:00:00Z',
      end_date: '2103-08-31T06:00:00Z',
      title: 'Closed Period',
      close_date: '2103-08-31T06:00:00Z',
      is_last: false,
      is_closed: true
    }
  ]
  const view = createView(this.assignment1)
  this.stub(view, 'currentUserIsAdmin').returns(true)
  const data = {
    name: 'Foo',
    due_at: '2103-08-15T06:00:00Z'
  }
  const errors = view.validateBeforeSave(data, [])
  notOk(errors.due_at)
})

test('requires name to save assignment', function() {
  const view = createView(this.assignment3)
  const data = {name: ''}
  const errors = view.validateBeforeSave(data, [])
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is required!')
})

test('has an error when a name has 257 chars', function() {
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 257, false, 30, '1')
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is too long, must be under 257 characters')
})

test('allows assignment to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', function() {
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 256, false, 30, '1')
  equal(errors.length, 0)
})

test('allows assignment to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', function() {
  this.assignment3.grading_type = 'not_graded'
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 15, true, 10, '1')
  equal(errors.length, 0)
})

test('has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and is required, and post_to_sis is true', function() {
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 11, true, 10, '1')
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(
    errors.name[0].message,
    `Name is too long, must be under ${ENV.MAX_NAME_LENGTH + 1} characters`
  )
})

test('allows assignment to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false', function() {
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 11, true, 10, '0')
  equal(errors.length, 0)
})

test('allows assignment to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true', function() {
  const view = createView(this.assignment3)
  const errors = nameLengthHelper(view, 10, true, 10, '1')
  equal(errors.length, 0)
})

test("don't validate name if it is frozen", function() {
  const view = createView(this.assignment3)
  this.assignment3.set('frozen_attributes', ['title'])
  const errors = view.validateBeforeSave({}, [])
  ok(!errors.name)
})

test('rejects a letter for points_possible', function() {
  const view = createView(this.assignment3)
  const data = {
    name: 'foo',
    points_possible: 'a'
  }
  const errors = view.validateBeforeSave(data, [])
  ok(errors.points_possible)
  equal(errors.points_possible[0].message, 'Points possible must be a number')
})

test('passes explicit submission_type for Assignment option', function() {
  const view = createView(this.group)
  const data = view.getFormData()
  equal(data.submission_types, 'none')
})

test('validates due date against date range', function() {
  const start_at = {
    date: new Date('August 20, 2013').toISOString(),
    date_context: 'term'
  }
  const end_at = {
    date: new Date('August 30, 2013').toISOString(),
    date_context: 'course'
  }
  ENV.VALID_DATE_RANGE = {
    start_at,
    end_at
  }
  const view = createView(this.assignment3)
  let data = {
    name: 'Example',
    due_at: new Date('September 1, 2013').toISOString()
  }
  let errors = view.validateBeforeSave(data, [])
  equal(errors.due_at[0].message, 'Due date cannot be after course end')
  data = {
    name: 'Example',
    due_at: new Date('July 1, 2013').toISOString()
  }
  errors = view.validateBeforeSave(data, [])
  ok(errors.due_at)
  equal(errors.due_at[0].message, 'Due date cannot be before term start')
  equal(start_at, ENV.VALID_DATE_RANGE.start_at)
  equal(end_at, ENV.VALID_DATE_RANGE.end_at)
})

test('validates due date for lock and unlock', function() {
  const view = createView(this.assignment4)
  let data = {
    name: 'Example',
    due_at: new Date('September 1, 2013').toISOString()
  }
  let errors = view.validateBeforeSave(data, [])
  ok(errors.due_at)
  equal(errors.due_at[0].message, 'Due date cannot be after lock date')
  data = {
    name: 'Example',
    due_at: new Date('July 1, 2013').toISOString()
  }
  errors = view.validateBeforeSave(data, [])
  ok(errors.due_at)
  equal(errors.due_at[0].message, 'Due date cannot be before unlock date')
})

test('renders due dates with locale-appropriate format string', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.short': '%-d %b',
    'date.abbr_month_names.8': 'août'
  })
  const view = createView(this.assignment1)
  equal(
    view
      .$('#vdd_tooltip_assign_1 div dd')
      .first()
      .text()
      .trim(),
    '28 août'
  )
})

test('renders due dates in appropriate time zone', function() {
  tz.changeZone(juneau, 'America/Juneau')
  I18nStubber.stub('en', {
    'date.formats.short': '%b %-d',
    'date.abbr_month_names.8': 'Aug'
  })
  const view = createView(this.assignment1)
  equal(
    view
      .$('#vdd_tooltip_assign_1 div dd')
      .first()
      .text()
      .trim(),
    'Aug 27'
  )
})
