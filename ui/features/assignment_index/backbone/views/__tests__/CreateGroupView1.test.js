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
import {waitFor} from '@testing-library/react'

const group = (id, opts = {}) =>
  new AssignmentGroup({
    id: id,
    name: 'something cool',
    assignments: [new Assignment(), new Assignment()],
    ...opts,
  })

const assignmentGroups = () => new AssignmentGroupCollection([group('0'), group('1')])

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
  let view
  let saveMock

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    fakeENV.teardown()
    if (view) {
      view.close()
      view.remove()
    }
    document.querySelectorAll('.ui-dialog').forEach(el => el.remove())
    document.body.innerHTML = ''
    jest.resetAllMocks()
  })

  test('it hides drop options for no assignments and undefined assignmentGroup id', async () => {
    // Create a view with assignments to ensure the drop options are initially shown
    view = createView({
      assignmentGroups: new AssignmentGroupCollection([
        group('0', {assignments: [new Assignment({id: '1'}), new Assignment({id: '2'})]}),
      ]),
    })
    document.getElementById('fixtures').appendChild(view.el)
    view.render()
    view.firstOpen()

    // Wait for the drop options to be rendered
    await waitFor(() => {
      // Check for the container elements which should always be present
      expect(view.$('.ag_0_drop_lowest_container').length).toBeGreaterThan(0)
      expect(view.$('.ag_0_drop_highest_container').length).toBeGreaterThan(0)
    })

    // Now reset the assignments to empty and verify drop options are hidden
    view.assignmentGroup.get('assignments').reset([])
    view.render()

    // The containers should still exist but the input elements should be removed
    expect(view.$('[name="rules[drop_lowest]"]')).toHaveLength(0)
    expect(view.$('[name="rules[drop_highest]"]')).toHaveLength(0)
  })

  test('it should not add errors when never_drop rules are added', () => {
    view = createView()
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
    view = createView({newGroup: true})
    view.render()
    view.onSaveSuccess()
    expect(view.assignmentGroups.size()).toBe(3)
  })

  test('it should edit an existing assignment group', () => {
    // Create a simpler view with minimal configuration
    view = createView()

    // Create a jQuery Deferred object that we can resolve immediately
    const deferred = $.Deferred()

    // Mock the save method to return our deferred
    saveMock = jest.spyOn(view.model, 'save').mockReturnValue(deferred)

    // Set up the view
    document.getElementById('fixtures').appendChild(view.el)
    view.render()

    // Change the name field
    view.$('#ag_0_name').val('IchangedIt')

    // Submit the form and immediately resolve the deferred
    view.submit()
    deferred.resolveWith(view.model, [{}, 'success'])

    // Verify the form data and that save was called
    const formData = view.getFormData()
    expect(formData.name).toBe('IchangedIt')
    expect(saveMock).toHaveBeenCalled()
  })

  test('it should not allow assignment groups with no name', () => {
    view = createView()
    const data = {name: ''}
    const errors = view.validateFormData(data)
    expect(errors['name'][0].type).toBe('no_name_error')
    expect(errors['name'][0].message).toBe(view.messages.no_name_error)
  })

  test('it should not allow assignment groups with names longer than 255 characters', () => {
    view = createView()
    const data = {name: 'a'.repeat(256)}
    const errors = view.validateFormData(data)
    expect(errors['name'][0].type).toBe('name_too_long_error')
    expect(errors['name'][0].message).toBe(view.messages.name_too_long_error)
  })

  test('it should not allow NaN values for group weight', () => {
    view = createView()
    const data = {
      name: 'Assignments',
      group_weight: 'not a number',
    }
    const errors = view.validateFormData(data)
    expect(errors['group_weight'][0].type).toBe('number')
    expect(errors['group_weight'][0].message).toBe(view.messages.non_number)
  })

  test('it should round group weight to 2 decimal places', () => {
    view = createView()
    const event = {target: $('<input>').val('10.12345')}
    view.roundWeight(event)
    expect($(event.target).val()).toBe('10.12')
  })

  test('it should show weight when course has apply_assignment_group_weights enabled', () => {
    view = createView()
    expect(view.showWeight()).toBe(true)
    view.course.set('apply_assignment_group_weights', false)
    expect(view.showWeight()).toBe(false)
  })

  test('it should allow weight changes for admin users', () => {
    view = createView({userIsAdmin: true})
    expect(view.canChangeWeighting()).toBe(true)
  })

  test('it should trigger a render event on save success when editing', () => {
    const triggerSpy = jest.spyOn(AssignmentGroupCollection.prototype, 'trigger')
    view = createView()
    view.onSaveSuccess()
    expect(triggerSpy).toHaveBeenCalledWith('render', view.model.collection)
  })

  test('it should call render on save success if adding an assignmentGroup', () => {
    view = createView({newGroup: true})
    jest.spyOn(view, 'render')
    view.onSaveSuccess()
    expect(view.render).toHaveBeenCalledTimes(1)
  })

  test('it shows a success message', () => {
    jest.spyOn(CreateGroupView.prototype, 'close').mockImplementation()
    jest.spyOn($, 'flashMessage').mockImplementation()
    jest.useFakeTimers()
    view = createView({newGroup: true})
    view.render()
    view.onSaveSuccess()
    jest.advanceTimersByTime(101)
    expect($.flashMessage).toHaveBeenCalledWith('Assignment group was saved successfully')
  })
})
