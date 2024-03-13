/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import EditHeaderView from 'ui/features/assignment_edit/backbone/views/EditHeaderView'
import editViewTemplate from 'ui/features/assignment_edit/jst/EditView.handlebars'
import fakeENV from 'helpers/fakeENV'
import Backbone from '@canvas/backbone'
import assertions from 'helpers/assertions'

const editHeaderView = function (
  assignmentOptions = {},
  viewOptions = {},
  beforeRender,
  defaultAssignmentOpts = {
    name: 'Test Assignment',
    assignment_overrides: [],
  }
) {
  Object.assign(assignmentOptions, defaultAssignmentOpts)
  const assignment = new Assignment(assignmentOptions)
  const app = new EditHeaderView({
    model: assignment,
    views: {edit_assignment_form: new Backbone.View({template: editViewTemplate})},
    userIsAdmin: viewOptions.userIsAdmin,
  })
  if (beforeRender) beforeRender(app)
  return app.render()
}

QUnit.module('EditHeaderView', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
    return $(document).on('submit', () => false)
  },
  teardown() {
    fakeENV.teardown()
    return $(document).off('submit')
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', assert => {
  const view = editHeaderView()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders', () => {
  const view = editHeaderView()
  ok(view.$('.assignment-edit-header').length > 0, 'header bar is rendered')
})

test('renders correct header title when the assignment is new and not an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {})
  strictEqual(view.$('.assignment-edit-header-title').text(), 'Create New Assignment')
})

test('renders correct screenreader content when the assignment is new and not an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {})
  ok(view.$('.screenreader-only').text().includes('Create New Assignment'))
})

test('renders correct header title when the assignment is new and is an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {is_quiz_lti_assignment: true})
  strictEqual(view.$('.assignment-edit-header-title').text(), 'Create Quiz')
})

test('renders correct screenreader content when the assignment is new and is an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {is_quiz_lti_assignment: true})
  ok(view.$('.screenreader-only').text().includes('Create Quiz'))
})

test('renders correct header title when the assignment is existing and is an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {name: 'Hello World', is_quiz_lti_assignment: true})
  strictEqual(view.$('.assignment-edit-header-title').text(), 'Edit Quiz')
})

test('renders correct header title when the assignment is existing and not an LTI quiz', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView()
  strictEqual(view.$('.assignment-edit-header-title').text(), 'Edit Assignment')
})

test('renders Not Published pill when the assignment is not a LTI quiz and has not been published', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {
    name: 'Hello World',
    published: false,
  })
  strictEqual(view.$('.published-assignment-container').text(), 'Not Published')
})

test('renders Published pill when the assignment is not a LTI quiz and has been published', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {
    name: 'Hello World',
    published: true,
  })
  strictEqual(view.$('.published-assignment-container').text(), 'Published')
})

test('renders Not Published pill when the assignment is a LTI quiz and has not been published', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {
    name: 'Hello World',
    is_quiz_lti_assignment: true,
    published: false,
  })
  strictEqual(view.$('.published-assignment-container').text(), 'Not Published')
})

test('renders Published pill when the assignment is a LTI quiz and has been published', () => {
  ENV.FEATURES.instui_nav = true
  const view = editHeaderView({}, {}, false, {
    name: 'Hello World',
    is_quiz_lti_assignment: true,
    published: true,
  })
  strictEqual(view.$('.published-assignment-container').text(), 'Published')
})

test('delete works for an un-saved assignment', () => {
  const view = editHeaderView()
  const cb = sandbox.stub(view, 'onDeleteSuccess')
  view.delete()
  equal(cb.called, true, 'onDeleteSuccess was called')
})

test('disallows deleting frozen assignments', () => {
  const view = editHeaderView({frozen: true})
  ok(view.$('.delete_assignment_link.disabled').length)
})

test('disallows deleting assignments due in closed grading periods', () => {
  const view = editHeaderView({in_closed_grading_period: true})
  ok(view.$('.delete_assignment_link.disabled').length)
})

test('allows deleting non-frozen assignments not due in closed grading periods', () => {
  const view = editHeaderView({
    frozen: false,
    in_closed_grading_period: false,
  })
  ok(view.$('.delete_assignment_link:not(.disabled)').length)
})

test('allows deleting frozen assignments for admins', () => {
  const view = editHeaderView({frozen: true}, {userIsAdmin: true})
  ok(view.$('.delete_assignment_link:not(.disabled)').length)
})

test('allows deleting assignments due in closed grading periods for admins', () => {
  const view = editHeaderView({in_closed_grading_period: true}, {userIsAdmin: true})
  ok(view.$('.delete_assignment_link:not(.disabled)').length)
})

test('does not attempt to delete an assignment due in a closed grading period', () => {
  const view = editHeaderView({in_closed_grading_period: true})
  sandbox.stub(window, 'confirm').returns(true)
  sandbox.spy(view, 'delete')
  view.$('.delete_assignment_link').click()
  ok(window.confirm.notCalled)
  ok(view.delete.notCalled)
})

QUnit.module('EditHeaderView - speed grader link', {
  setup() {
    fakeENV.setup()
    ENV.SHOW_SPEED_GRADER_LINK = true
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('shows when assignment is published', () => {
  const view = editHeaderView({published: true})
  ok(view.$('.speed-grader-link-container').length)
})

test('does not show when assignment is not published', () => {
  ENV.SHOW_SPEED_GRADER_LINK = false
  const view = editHeaderView({published: false})
  strictEqual(view.$('.speed-grader-link-container').length, 0)
})

QUnit.module('EditHeaderView - try deleting assignment', {
  setup() {
    fakeENV.setup()
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = {
      assignment: {id: 1},
    }
  },
  teardown() {
    fakeENV.teardown()
    return window.$.restore()
  },
})

test('attempt to delete an assignment, but clicked Cancel on confirmation box', () => {
  const view = editHeaderView({in_closed_grading_period: false})
  sandbox.stub(window, 'confirm').returns(false)
  sandbox.spy(view, 'delete')
  const setFocusStub = sinon.stub()
  sinon
    .stub(window, '$')
    .withArgs('a:first[role="button"].al-trigger.btn')
    .returns({focus: setFocusStub})
  view.$('.delete_assignment_link').click()
  ok(window.confirm.called)
  ok(view.delete.notCalled)
  ok(setFocusStub.called)
})

QUnit.module('EditHeaderView - ConditionalRelease', {
  setup() {
    fakeENV.setup()
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = {
      assignment: {id: 1},
    }
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('disables conditional release tab on load when grading type is not_graded', () => {
  const view = editHeaderView({grading_type: 'not_graded'})
  equal(view.$headerTabsCr.tabs('option', 'disabled'), true)
})

test('enables conditional release tab when grading type switched from not_graded', () => {
  const view = editHeaderView({grading_type: 'not_graded'})
  view.onGradingTypeUpdate({target: {value: 'points'}})
  equal(view.$headerTabsCr.tabs('option', 'disabled'), false)
})

test('disables conditional release tab when grading type switched to not_graded', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.onGradingTypeUpdate({target: {value: 'not_graded'}})
  equal(view.$headerTabsCr.tabs('option', 'disabled'), true)
})

test('switches to conditional release tab if save error contains conditional release error', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.editView.updateConditionalRelease = () => ({})
  view.$headerTabsCr.tabs('option', 'active', 0)
  view.onShowErrors({
    foo: 'bar',
    conditional_release: 'baz',
  })
  equal(view.$headerTabsCr.tabs('option', 'active'), 1)
})

test('switches to details tab if save error does not contain conditional release error', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.editView.updateConditionalRelease = () => ({})
  view.$headerTabsCr.tabs('option', 'active', 1)
  view.onShowErrors({
    foo: 'bar',
    baz: 'bat',
  })
  equal(view.$headerTabsCr.tabs('option', 'active'), 0)
})
