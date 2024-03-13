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

import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DeleteGroupView from 'ui/features/assignment_index/backbone/views/DeleteGroupView'
import $ from 'jquery'
import 'jquery-migrate'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

const group = (assignments = true, id) =>
  new AssignmentGroup({
    id,
    name: `something cool ${id}`,
    assignments: assignments ? [new Assignment(), new Assignment()] : [],
  })
const assignmentGroups = function (assignments = true, multiple = true) {
  const groups = multiple ? [group(assignments, 1), group(assignments, 2)] : [group(assignments, 1)]
  return new AssignmentGroupCollection(groups)
}
const createView = function (assignments = true, multiple = true) {
  const ags = assignmentGroups(assignments, multiple)
  const ag_group = ags.first()
  return new DeleteGroupView({model: ag_group})
}

QUnit.module('DeleteGroupView', {
  setup() {},
  teardown() {
    $('#fixtures').empty()
    return $('form.dialogFormView').remove()
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', assert => {
  const view = createView(false, true)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('it should delete a group without assignments', () => {
  sandbox.stub(window, 'confirm').returns(true)
  const view = createView(false, true)
  sandbox.stub(view, 'destroyModel')
  view.render()
  view.open()
  ok(window.confirm.called)
  ok(view.destroyModel.called)
})

test('assignment and ag counts should be correct', () => {
  const view = createView(true, true)
  view.render()
  view.open()
  equal(view.$('.assignment_count:visible').text(), '2')
  equal(view.$('.group_select option').length, 2)
  return view.close()
})

test('assignment and ag counts should update', () => {
  const view = createView(true, true)
  view.render()
  view.open()
  view.close()
  view.model.get('assignments').add(new Assignment())
  view.model.collection.add(new AssignmentGroup())
  view.open()
  equal(view.$('.assignment_count:visible').text(), '3')
  equal(view.$('.group_select:visible option').length, 3)
  return view.close()
})

test('it should delete a group with assignments', () => {
  const view = createView(true, true)
  const destroy_spy = sandbox.stub(view, 'destroyModel').returns($.Deferred().resolve())
  view.render()
  view.open()
  view.$('.delete_group').click()
  ok(destroy_spy.called)
  return view.close()
})

test('it validates that an assignment group to move to is selected', () => {
  const view = createView(true, true)
  view.render()
  view.open()
  view.$('.assignment_group_move').click()
  const errors = view.validateFormData(view.getFormData())
  equal(errors.move_assignments_to[0].type, 'required')
})

test('it should move assignments to another group', () => {
  const view = createView(true, true)
  const destroy_spy = sandbox.stub(view, 'destroyModel').returns($.Deferred().resolve())
  view.render()
  view.open()
  view.$('.assignment_group_move').click()
  view.$('select').val(2)
  view.$('.delete_group').click()
  ok(destroy_spy.called)
  return view.close()
})

test('it should not delete the last assignment group', () => {
  const alert_stub = sandbox.stub(window, 'alert').returns(true)
  const view = createView(true, false)
  const destroy_spy = sandbox.spy(view, 'destroyModel')
  view.render()
  view.open()
  ok(alert_stub.called)
  ok(!destroy_spy.called)
  return view.close()
})
