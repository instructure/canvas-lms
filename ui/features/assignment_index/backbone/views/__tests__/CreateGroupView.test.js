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

import {isEmpty} from 'lodash'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import Course from '@canvas/courses/backbone/models/Course'
import CreateGroupView from '../CreateGroupView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'

const group = (opts = {}) =>
  new AssignmentGroup({
    name: 'something cool',
    assignments: [new Assignment(), new Assignment()],
    ...opts,
  })

const assignmentGroups = () => new AssignmentGroupCollection([group(), group()])

const createView = function (opts = {}) {
  const groups = opts.assignmentGroups || assignmentGroups()
  const args = {
    course: opts.course || new Course({apply_assignment_group_weights: true}),
    assignmentGroups: groups,
    assignmentGroup: opts.group || (opts.newGroup == null ? groups.first() : undefined),
    userIsAdmin: opts.userIsAdmin,
  }
  return new CreateGroupView(args)
}

describe('CreateGroupView', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    $('form[id^=ui-id-]').remove()
  })

  test('it hides drop options for no assignments and undefined assignmentGroup id', () => {
    const view = createView()
    view.render()
    expect(view.$('[name="rules[drop_lowest]"]').length).toBeGreaterThan(0)
    expect(view.$('[name="rules[drop_highest]"]').length).toBeGreaterThan(0)
    view.assignmentGroup.get('assignments').reset([])
    view.render()
    expect(view.$('[name="rules[drop_lowest]"]')).toHaveLength(0)
    expect(view.$('[name="rules[drop_highest]"]')).toHaveLength(0)
  })

  test('it should not add errors when never_drop rules are added', () => {
    const view = createView()
    const data = {
      name: 'Assignments',
      rules: {
        never_drop: ['1854', '352', '234563'],
      },
    }
    const errors = view.validateFormData(data)
    expect(isEmpty(errors)).toBe(true)
  })

  test('it should create a new assignment group', () => {
    jest.spyOn(CreateGroupView.prototype, 'close').mockImplementation()
    const view = createView({newGroup: true})
    view.render()
    view.onSaveSuccess()
    expect(view.assignmentGroups.size()).toBe(3)
  })

  test('it should edit an existing assignment group', async () => {
    const view = createView()
    const deferred = $.Deferred()
    const saveSpy = jest.spyOn(view.model, 'save').mockReturnValue(deferred)
    view.render()
    view.open()
    view.$('#ag_new_name').val('IchangedIt')
    view.$('#ag_new_drop_lowest').val('1')
    view.$('#ag_new_drop_highest').val('1')
    const submitPromise = view.submit()
    deferred.resolve()
    await submitPromise
    const formData = view.getFormData()
    expect(formData.name).toBe('IchangedIt')
    expect(parseInt(formData.rules.drop_lowest, 10)).toBe(1)
    expect(parseInt(formData.rules.drop_highest, 10)).toBe(1)
    expect(saveSpy).toHaveBeenCalled()
  })

  test('it should not save drop rules when none are given', async () => {
    const view = createView()
    const deferred = $.Deferred()
    const saveSpy = jest.spyOn(view.model, 'save').mockReturnValue(deferred)
    view.render()
    view.open()
    view.$('#ag_new_drop_lowest').val('')
    expect(view.$('#ag_new_drop_highest').val()).toBe('0')
    view.$('#ag_new_name').val('IchangedIt')
    const submitPromise = view.submit()
    deferred.resolve()
    await submitPromise
    const formData = view.getFormData()
    expect(formData.name).toBe('IchangedIt')
    expect(Object.keys(formData.rules)).toHaveLength(0)
    expect(saveSpy).toHaveBeenCalled()
  })

  test('it should only allow positive numbers for drop rules', () => {
    const view = createView()
    const data = {
      name: 'Assignments',
      rules: {
        drop_lowest: 'tree',
        drop_highest: -1,
        never_drop: ['1', '2', '3'],
      },
    }
    const errors = view.validateFormData(data)
    expect(errors).toBeTruthy()
    expect(Object.keys(errors)).toHaveLength(2)
  })

  test('it should only allow less than the number of assignments for drop rules', () => {
    const view = createView()
    const data = {
      name: 'Assignments',
      rules: {drop_highest: 5},
    }
    const errors = view.validateFormData(data)
    expect(errors).toBeTruthy()
    expect(Object.keys(errors)).toHaveLength(1)
  })

  test('it should only allow integer values for rules', () => {
    const view = createView()
    const data = {
      name: 'Assignments',
      rules: {drop_highest: 2.5},
    }
    const errors = view.validateFormData(data)
    expect(errors).toBeTruthy()
    expect(Object.keys(errors)).toHaveLength(1)
  })

  test('it should not allow assignment groups with no name', () => {
    const view = createView()
    const data = {name: ''}
    const errors = view.validateFormData(data)
    expect(errors.name[0].type).toBe('no_name_error')
    expect(errors.name[0].message).toBe(view.messages.no_name_error)
  })

  test('it should not allow assignment groups with names longer than 255 characters', () => {
    const view = createView()
    const data = {name: 'a'.repeat(256)}
    const errors = view.validateFormData(data)
    expect(errors.name[0].type).toBe('name_too_long_error')
    expect(errors.name[0].message).toBe(view.messages.name_too_long_error)
  })

  test('it should not allow NaN values for group weight', () => {
    const view = createView()
    const data = {
      name: 'Assignments',
      group_weight: 'not a number',
    }
    const errors = view.validateFormData(data)
    expect(errors.group_weight[0].type).toBe('number')
    expect(errors.group_weight[0].message).toBe(view.messages.non_number)
  })

  test('it should round group weight to 2 decimal places', () => {
    const view = createView()
    const event = {target: $('<input>').val('10.12345')}
    view.roundWeight(event)
    expect($(event.target).val()).toBe('10.12')
  })

  test('it should show weight when course has apply_assignment_group_weights enabled', () => {
    const view = createView()
    expect(view.showWeight()).toBe(true)
    view.course.set('apply_assignment_group_weights', false)
    expect(view.showWeight()).toBe(false)
  })

  test('it should allow weight changes for admin users', () => {
    const view = createView({userIsAdmin: true})
    expect(view.canChangeWeighting()).toBe(true)
  })

  test('it should trigger a render event on save success when editing', () => {
    const triggerSpy = jest.spyOn(AssignmentGroupCollection.prototype, 'trigger')
    const view = createView()
    view.onSaveSuccess()
    expect(triggerSpy).toHaveBeenCalledWith('render', view.model.collection)
  })

  test('it should call render on save success if adding an assignmentGroup', () => {
    const view = createView({newGroup: true})
    jest.spyOn(view, 'render')
    view.onSaveSuccess()
    expect(view.render).toHaveBeenCalledTimes(1)
  })

  test('it shows a success message', () => {
    jest.spyOn(CreateGroupView.prototype, 'close').mockImplementation()
    jest.spyOn($, 'flashMessage').mockImplementation()
    jest.useFakeTimers()
    const view = createView({newGroup: true})
    view.render()
    view.onSaveSuccess()
    jest.advanceTimersByTime(101)
    expect($.flashMessage).toHaveBeenCalledWith('Assignment group was saved successfully')
  })
})
