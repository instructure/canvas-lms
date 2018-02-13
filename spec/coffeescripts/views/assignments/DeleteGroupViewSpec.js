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

import Backbone from 'Backbone'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import AssignmentCollection from 'compiled/collections/AssignmentCollection'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Assignment from 'compiled/models/Assignment'
import DeleteGroupView from 'compiled/views/assignments/DeleteGroupView'
import $ from 'jquery'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

const group = (assignments = true, id) =>
  new AssignmentGroup({
    id,
    name: `something cool ${id}`,
    assignments: assignments ? [new Assignment(), new Assignment()] : []
  })
const assignmentGroups = function(assignments = true, multiple = true) {
  const groups = multiple ? [group(assignments, 1), group(assignments, 2)] : [group(assignments, 1)]
  return new AssignmentGroupCollection(groups)
}
const createView = function(assignments = true, multiple = true) {
  const ags = assignmentGroups(assignments, multiple)
  const ag_group = ags.first()
  return new DeleteGroupView({model: ag_group})
}

QUnit.module('DeleteGroupView', {
  setup() {},
  teardown() {
    $('#fixtures').empty()
    return $('form.dialogFormView').remove()
  }
})

test('should be accessible', assert => {
  const view = createView(false, true)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('it should delete a group without assignments', function() {
  this.stub(window, 'confirm').returns(true)
  const view = createView(false, true)
  this.stub(view, 'destroyModel')
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

test('it should delete a group with assignments', function() {
  const destroy_stub = this.stub(DeleteGroupView.prototype, 'destroy')
  const view = createView(true, true)
  view.render()
  view.open()
  view.$('.delete_group').click()
  ok(destroy_stub.called)
  return view.close()
})

test('it should not delete the last assignment group', function() {
  const alert_stub = this.stub(window, 'alert').returns(true)
  const view = createView(true, false)
  const destroy_spy = this.spy(view, 'destroyModel')
  view.render()
  view.open()
  ok(alert_stub.called)
  ok(!destroy_spy.called)
  return view.close()
})
