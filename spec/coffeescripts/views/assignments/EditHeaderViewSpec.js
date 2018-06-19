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
import Assignment from 'compiled/models/Assignment'
import EditHeaderView from 'compiled/views/assignments/EditHeaderView'
import editViewTemplate from 'jst/assignments/EditView'
import fakeENV from 'helpers/fakeENV'
import Backbone from 'Backbone'
import assertions from 'helpers/assertions'

const defaultAssignmentOpts = {
  name: 'Test Assignment',
  assignment_overrides: []
}
const editHeaderView = function(assignmentOptions = {}, viewOptions = {}, beforeRender) {
  Object.assign(assignmentOptions, defaultAssignmentOpts)
  const assignment = new Assignment(assignmentOptions)
  const app = new EditHeaderView({
    model: assignment,
    views: {edit_assignment_form: new Backbone.View({template: editViewTemplate})},
    userIsAdmin: viewOptions.userIsAdmin
  })
  if (beforeRender) beforeRender(app)
  return app.render()
}

QUnit.module('EditHeaderView', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher']})
    return $(document).on('submit', () => false)
  },
  teardown() {
    fakeENV.teardown()
    return $(document).off('submit')
  }
})

test('should be accessible', assert => {
  const view = editHeaderView()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders', () => {
  const view = editHeaderView()
  ok(view.$('.header-bar-right').length > 0, 'header bar is rendered')
})

test('renders the moderated grading form field group if Anonymous Moderated Marking is enabled', () => {
  ENV.ANONYMOUS_MODERATED_MARKING_ENABLED = true
  function beforeRender(editView) {
    sinon.stub(editView.model, 'renderModeratedGradingFormFieldGroup')
  }
  const view = editHeaderView({}, {}, beforeRender)
  strictEqual(view.model.renderModeratedGradingFormFieldGroup.callCount, 1)
  view.model.renderModeratedGradingFormFieldGroup.restore()
})

test('does not render the moderated grading form field group if Anonymous Moderated Marking is disabled', () => {
  function beforeRender(editView) {
    sinon.stub(editView.model, 'renderModeratedGradingFormFieldGroup')
  }
  const view = editHeaderView({}, {}, beforeRender)
  strictEqual(view.model.renderModeratedGradingFormFieldGroup.callCount, 0)
  view.model.renderModeratedGradingFormFieldGroup.restore()
})

test('delete works for an un-saved assignment', function() {
  const view = editHeaderView()
  const cb = this.stub(view, 'onDeleteSuccess')
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
    in_closed_grading_period: false
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

test('does not attempt to delete an assignment due in a closed grading period', function() {
  const view = editHeaderView({in_closed_grading_period: true})
  this.stub(window, 'confirm').returns(true)
  this.spy(view, 'delete')
  view.$('.delete_assignment_link').click()
  ok(window.confirm.notCalled)
  ok(view.delete.notCalled)
})

QUnit.module('EditHeaderView - try deleting assignment', {
  setup() {
    fakeENV.setup()
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = {
      assignment: {id: 1},
      jwt: 'foo'
    }
  },
  teardown() {
    fakeENV.teardown()
    return window.$.restore()
  }
})

test('attempt to delete an assignment, but clicked Cancel on confirmation box', function() {
  const view = editHeaderView({in_closed_grading_period: false})
  this.stub(window, 'confirm').returns(false)
  this.spy(view, 'delete')
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
      jwt: 'foo'
    }
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('disables conditional release tab on load when grading type is not_graded', () => {
  const view = editHeaderView({grading_type: 'not_graded'})
  equal(true, view.$headerTabsCr.tabs('option', 'disabled'))
})

test('enables conditional release tab when grading type switched from not_graded', () => {
  const view = editHeaderView({grading_type: 'not_graded'})
  view.onGradingTypeUpdate({target: {value: 'points'}})
  equal(false, view.$headerTabsCr.tabs('option', 'disabled'))
})

test('disables conditional release tab when grading type switched to not_graded', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.onGradingTypeUpdate({target: {value: 'not_graded'}})
  equal(true, view.$headerTabsCr.tabs('option', 'disabled'))
})

test('switches to conditional release tab if save error contains conditional release error', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.editView.updateConditionalRelease = () => ({})
  view.$headerTabsCr.tabs('option', 'active', 0)
  view.onShowErrors({
    foo: 'bar',
    conditional_release: 'baz'
  })
  equal(1, view.$headerTabsCr.tabs('option', 'active'))
})

test('switches to details tab if save error does not contain conditional release error', () => {
  const view = editHeaderView({grading_type: 'points'})
  view.editView.updateConditionalRelease = () => ({})
  view.$headerTabsCr.tabs('option', 'active', 1)
  view.onShowErrors({
    foo: 'bar',
    baz: 'bat'
  })
  equal(0, view.$headerTabsCr.tabs('option', 'active'))
})
