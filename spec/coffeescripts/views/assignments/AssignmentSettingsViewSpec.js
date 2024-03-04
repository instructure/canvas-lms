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
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import AssignmentSettingsView from 'ui/features/assignment_index/backbone/views/AssignmentSettingsView'
import AssignmentGroupWeightsView from 'ui/features/assignment_index/backbone/views/AssignmentGroupWeightsView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

const group = (opts = {}) => new AssignmentGroup({group_weight: 50, ...opts})

const assignmentGroups = () =>
  new AssignmentGroupCollection([group({name: 'G1'}), group({name: 'G2'})])

const createView = function (opts = {}) {
  const course = new Course({apply_assignment_group_weights: opts.weighted})
  course.urlRoot = '/courses/1' // without this it keeps throwing an error
  const view = new AssignmentSettingsView({
    model: course,
    assignmentGroups: opts.assignmentGroups || assignmentGroups(),
    weightsView: AssignmentGroupWeightsView,
    userIsAdmin: opts.userIsAdmin,
  })
  view.open()
  return view
}

QUnit.module('AssignmentSettingsView', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
    $('.ui-dialog').remove()
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', assert => {
  const view = createView({weighted: true})
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('sets the checkbox to the right value on open', () => {
  let view = createView({weighted: true})
  ok(view.$('#apply_assignment_group_weights').prop('checked'))
  view.remove()
  view = createView({weighted: false})
  ok(!view.$('#apply_assignment_group_weights').prop('checked'))
  view.remove()
})

test('shows the weights table when checked', () => {
  const view = createView({weighted: true})
  ok(view.$('#ag_weights_wrapper').is(':visible'))
  view.remove()
})

test('hides the weights table when clicked', () => {
  const view = createView({weighted: true})
  ok(view.$('#ag_weights_wrapper').is(':visible'))
  view.$('#apply_assignment_group_weights').click()
  ok(view.$('#ag_weights_wrapper').not(':visible'))
  view.remove()
})

test('calculates the total weight', () => {
  const view = createView({weighted: true})
  equal(view.$('#percent_total').text(), '100%')
})

test('changes the apply_assignment_group_weights flag', () => {
  const view = createView({weighted: true})
  view.$('#apply_assignment_group_weights').click()
  const attributes = view.getFormData()
  equal(attributes.apply_assignment_group_weights, '0')
  view.remove()
})

test('onSaveSuccess triggers weightedToggle event with expected argument', () => {
  const sandbox = sinon.createSandbox()
  const stub1 = sandbox.stub()
  let view = createView({weighted: true})
  view.on('weightedToggle', stub1)
  view.onSaveSuccess()
  equal(stub1.callCount, 1)
  deepEqual(stub1.getCall(0).args, [true])
  view.remove()
  const stub2 = sandbox.stub()
  view = createView({weighted: false})
  view.on('weightedToggle', stub2)
  view.onSaveSuccess()
  equal(stub2.callCount, 1)
  deepEqual(stub2.getCall(0).args, [false])
  view.remove()
  sandbox.restore()
})

test('saves group weights', () => {
  const view = createView({weighted: true})
  view.$('.ag-weights-tr:eq(0) .group_weight_value').val('20')
  view.$('.ag-weights-tr:eq(1) .group_weight_value').val('80')
  view.$('#update-assignment-settings').click()
  equal(view.assignmentGroups.first().get('group_weight'), 20)
  equal(view.assignmentGroups.last().get('group_weight'), 80)
  view.remove()
})

QUnit.module('AssignmentSettingsView with an assignment in a closed grading period', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('disables the checkbox', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  ok(view.$('#apply_assignment_group_weights').hasClass('disabled'))
  ok(view.$('#ag_weights_wrapper').is(':visible'))
  ok(view.$('#apply_assignment_group_weights').prop('checked'))
  view.$('#apply_assignment_group_weights').simulate('click')
  ok(view.$('#ag_weights_wrapper').is(':visible'))
  ok(view.$('#apply_assignment_group_weights').prop('checked'))
  view.remove()
})

test('does not disable the checkbox when the user is an admin', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
    userIsAdmin: true,
  })
  notOk(view.$('#apply_assignment_group_weights').hasClass('disabled'))
  ok(view.$('#ag_weights_wrapper').is(':visible'))
  ok(view.$('#apply_assignment_group_weights').prop('checked'))
  view.$('#apply_assignment_group_weights').click()
  ok(view.$('#ag_weights_wrapper').not(':visible'))
  notOk(view.$('#apply_assignment_group_weights').prop('checked'))
  view.remove()
})

test('does not change the apply_assignment_group_weights flag', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  view.$('#apply_assignment_group_weights').simulate('click')
  const attributes = view.getFormData()
  equal(attributes.apply_assignment_group_weights, '1')
  view.remove()
})

test('changes the apply_assignment_group_weights flag when the user is an admin', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
    userIsAdmin: true,
  })
  view.$('#apply_assignment_group_weights').click()
  const attributes = view.getFormData()
  equal(attributes.apply_assignment_group_weights, '0')
  view.remove()
})

test('disables the weight input fields in the table', () => {
  const closed_group = group({
    any_assignment_in_closed_grading_period: true,
    group_weight: 35,
  })
  const groups = new AssignmentGroupCollection([group({group_weight: 25}), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  ok(view.$('.ag-weights-tr:eq(0) .group_weight_value').attr('readonly'))
  ok(view.$('.ag-weights-tr:eq(1) .group_weight_value').attr('readonly'))
})

test('disables the Save and Cancel buttons', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  ok(view.$('#cancel-assignment-settings').hasClass('disabled'))
  ok(view.$('#update-assignment-settings').hasClass('disabled'))
  view.remove()
})

test('disables the Save and Cancel button handlers', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  sandbox.spy(view, 'saveFormData')
  sandbox.spy(view, 'cancel')
  view.$('#cancel-assignment-settings').click()
  view.$('#update-assignment-settings').click()
  notOk(view.saveFormData.called)
  notOk(view.cancel.called)
  view.remove()
})

test('does not allow NaN values to be saved', () => {
  const closed_group = group({any_assignment_in_closed_grading_period: true})
  const groups = new AssignmentGroupCollection([group(), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  const weight_input = view.$el.find('.group_weight_value')[0]
  $(weight_input).val('weight for it')
  const errors = view.validateFormData()
  ok(errors)
  equal(Object.keys(errors).length, 1)
})

test('calculates the total weight', () => {
  const closed_group = group({
    any_assignment_in_closed_grading_period: true,
    group_weight: 35,
  })
  const groups = new AssignmentGroupCollection([group({group_weight: 25}), closed_group])
  const view = createView({
    weighted: true,
    assignmentGroups: groups,
  })
  equal(view.$('#percent_total').text(), '60%')
})
