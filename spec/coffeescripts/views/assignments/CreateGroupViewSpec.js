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

import {isEmpty, keys} from 'lodash'
import Backbone from 'Backbone'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Assignment from 'compiled/models/Assignment'
import Course from 'compiled/models/Course'
import CreateGroupView from 'compiled/views/assignments/CreateGroupView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

const group = (opts = {}) =>
  new AssignmentGroup({
    name: 'something cool',
    assignments: [new Assignment(), new Assignment()],
    ...opts
  })
const assignmentGroups = () => new AssignmentGroupCollection([group(), group()])
const createView = function(opts = {}) {
  const groups = opts.assignmentGroups || assignmentGroups()
  const args = {
    course: opts.course || new Course({apply_assignment_group_weights: true}),
    assignmentGroups: groups,
    assignmentGroup: opts.group || (opts.newGroup == null ? groups.first() : undefined),
    userIsAdmin: opts.userIsAdmin
  }
  return new CreateGroupView(args)
}

QUnit.module('CreateGroupView', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
    return $('form[id^=ui-id-]').remove()
  }
})

test('should be accessible', assert => {
  const view = createView()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('hides drop options for no assignments', () => {
  const view = createView()
  view.render()
  ok(view.$('[name="rules[drop_lowest]"]').length)
  ok(view.$('[name="rules[drop_highest]"]').length)
  view.assignmentGroup.get('assignments').reset([])
  view.render()
  equal(view.$('[name="rules[drop_lowest]"]').length, 0)
  equal(view.$('[name="rules[drop_highest]"]').length, 0)
})

test('it should not add errors when never_drop rules are added', () => {
  const view = createView()
  const data = {
    name: 'Assignments',
    rules: {
      never_drop: ['1854', '352', '234563']
    }
  }
  const errors = view.validateFormData(data)
  ok(isEmpty(errors))
})

test('it should create a new assignment group', function() {
  sandbox.stub(CreateGroupView.prototype, 'close')
  const view = createView({newGroup: true})
  view.render()
  view.onSaveSuccess()
  equal(view.assignmentGroups.size(), 3)
})

test('it should edit an existing assignment group', function() {
  const view = createView()
  const save_spy = sandbox.stub(view.model, 'save').returns($.Deferred().resolve())
  view.render()
  view.open()
  view.$('#ag_new_name').val('IchangedIt')
  view.$('#ag_new_drop_lowest').val('1')
  view.$('#ag_new_drop_highest').val('1')
  view.$('.create_group').click()
  const formData = view.getFormData()
  equal(formData.name, 'IchangedIt')
  equal(formData.rules.drop_lowest, 1)
  equal(formData.rules.drop_highest, 1)
  ok(save_spy.called)
})

test('it should not save drop rules when none are given', function() {
  const view = createView()
  const save_spy = sandbox.stub(view.model, 'save').returns($.Deferred().resolve())
  view.render()
  view.open()
  view.$('#ag_new_drop_lowest').val('')
  equal(view.$('#ag_new_drop_highest').val(), '0')
  view.$('#ag_new_name').val('IchangedIt')
  view.$('.create_group').click()
  const formData = view.getFormData()
  equal(formData.name, 'IchangedIt')
  equal(keys(formData.rules).length, 0)
  ok(save_spy.called)
})

test('it should only allow positive numbers for drop rules', () => {
  const view = createView()
  const data = {
    name: 'Assignments',
    rules: {
      drop_lowest: 'tree',
      drop_highest: -1,
      never_drop: ['1', '2', '3']
    }
  }
  const errors = view.validateFormData(data)
  ok(errors)
  equal(keys(errors).length, 2)
})

test('it should only allow less than the number of assignments for drop rules', () => {
  const view = createView()
  const assignments = view.assignmentGroup.get('assignments')
  const data = {
    name: 'Assignments',
    rules: {drop_highest: 5}
  }
  const errors = view.validateFormData(data)
  ok(errors)
  equal(keys(errors).length, 1)
})

test('it should not allow assignment groups with no name', () => {
  const view = createView()
  const assignments = view.assignmentGroup.get('assignments')
  const data = {name: ''}
  const errors = view.validateFormData(data)
  ok(errors)
  equal(keys(errors).length, 1)
})

test('it should not allow NaN values for group weight', () => {
  const view = createView()
  const assignments = view.assignmentGroup.get('assignments')
  const data = {
    name: 'Assignments',
    drop_highest: '0',
    drop_lowest: '0',
    group_weight: 'the weighting is the hardest part'
  }
  const errors = view.validateFormData(data)
  ok(errors)
  equal(keys(errors).length, 1)
})

test('it should trigger a render event on save success when editing', function() {
  const triggerSpy = sandbox.spy(AssignmentGroupCollection.prototype, 'trigger')
  const view = createView()
  view.onSaveSuccess()
  ok(triggerSpy.calledWith('render'))
})

test('it should call render on save success if adding an assignmentGroup', function() {
  const view = createView({newGroup: true})
  sandbox.stub(view, 'render')
  view.onSaveSuccess()
  equal(view.render.callCount, 1)
})

test('it shows a success message', function() {
  sandbox.stub(CreateGroupView.prototype, 'close')
  sandbox.spy($, 'flashMessage')
  const clock = sinon.useFakeTimers()
  const view = createView({newGroup: true})
  view.render()
  view.onSaveSuccess()
  clock.tick(101)
  equal($.flashMessage.callCount, 1)
  return clock.restore()
})

test('does not render group weight input when the course is not using weights', () => {
  const groups = new AssignmentGroupCollection([group(), group()])
  const course = new Course({apply_assignment_group_weights: false})
  const view = createView({
    assignmentGroups: groups,
    course
  })
  view.render()
  notOk(view.showWeight())
  notOk(view.$('[name="group_weight"]').length)
})

test('disables group weight input when an assignment is due in a closed grading period', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    group: closed_group,
    assignmentGroups: groups
  })
  view.render()
  notOk(view.canChangeWeighting())
  ok(view.$('[name="group_weight"]').attr('readonly'))
})

test('does not disable group weight input when userIsAdmin is true', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    group: closed_group,
    assignmentGroups: groups,
    userIsAdmin: true
  })
  view.render()
  ok(view.canChangeWeighting())
  notOk(view.$('[name="group_weight"]').attr('readonly'))
})

test('disables drop rule inputs when an assignment is due in a closed grading period', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    group: closed_group,
    assignmentGroups: groups
  })
  view.render()
  ok(view.$('[name="rules[drop_lowest]"]').attr('readonly'))
  ok(view.$('[name="rules[drop_highest]"]').attr('readonly'))
})

test('does not disable drop rule inputs when userIsAdmin is true', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    group: closed_group,
    assignmentGroups: groups,
    userIsAdmin: true
  })
  view.render()
  notOk(view.$('[name="rules[drop_lowest]"]').attr('readonly'))
  notOk(view.$('[name="rules[drop_highest]"]').attr('readonly'))
})
