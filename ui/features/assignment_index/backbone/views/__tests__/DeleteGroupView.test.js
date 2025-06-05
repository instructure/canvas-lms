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
import DeleteGroupView from '../DeleteGroupView'
import $ from 'jquery'
import '@testing-library/jest-dom'
import axe from 'axe-core'

describe('DeleteGroupView', () => {
  let container

  beforeAll(() => {
    window.ENV = {
      context_asset_string: 'course_1',
    }
  })

  const group = (assignments = true, id) =>
    new AssignmentGroup({
      id,
      name: `something cool ${id}`,
      assignments: assignments ? [new Assignment(), new Assignment()] : [],
    })

  const assignmentGroups = (assignments = true, multiple = true) => {
    const groups = multiple
      ? [group(assignments, 1), group(assignments, 2)]
      : [group(assignments, 1)]
    return new AssignmentGroupCollection(groups)
  }

  const createView = (assignments = true, multiple = true) => {
    const ags = assignmentGroups(assignments, multiple)
    const ag_group = ags.first()
    const view = new DeleteGroupView({model: ag_group})

    // Mock dialog functionality
    view.dialog = {
      open: jest.fn(),
      close: jest.fn(),
      isOpen: jest.fn(() => true),
      focusable: {
        focus: jest.fn(),
      },
    }

    // Mock jQuery dialog
    view.$el.dialog = function () {
      return view.dialog
    }

    // Mock form validation and submission
    view.validateBeforeSave = jest.fn(() => true)
    view.saveFormData = jest.fn(() => $.Deferred().resolve().promise())

    return view
  }

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    container.remove()
    $('form.dialogFormView').remove()
    jest.clearAllMocks()
  })

  it('should be accessible', async () => {
    const view = createView(false, true)
    view.render()
    const results = await axe.run(view.el)
    expect(results.violations).toHaveLength(0)
  })

  it('should delete a group without assignments', () => {
    const confirmSpy = jest.spyOn(window, 'confirm').mockImplementation(() => true)
    const view = createView(false, true)
    const destroyModelSpy = jest.spyOn(view, 'destroyModel')
    jest.spyOn(view.model, 'destroy').mockImplementation(() => Promise.resolve())

    view.render()
    view.openAgain()

    expect(confirmSpy).toHaveBeenCalled()
    expect(destroyModelSpy).toHaveBeenCalled()
  })

  it('displays correct assignment and group counts', () => {
    const view = createView(true, true)
    view.render()

    const $assignmentCount = $(view.el).find('.assignment_count')
    const $groupSelect = $(view.el).find('.group_select')

    expect($assignmentCount.text()).toBe('2')
    expect($groupSelect.find('option')).toHaveLength(2)
  })

  it('updates assignment and group counts when changed', () => {
    const view = createView(true, true)
    view.render()

    view.model.get('assignments').add(new Assignment())
    view.model.collection.add(new AssignmentGroup())

    const $assignmentCount = $(view.el).find('.assignment_count')
    const $groupSelect = $(view.el).find('.group_select')

    expect($assignmentCount.text()).toBe('3')
    expect($groupSelect.find('option')).toHaveLength(3)
  })

  it('deletes a group with assignments', () => {
    const view = createView(true, true)
    const destroyModelSpy = jest.spyOn(view, 'destroyModel')
    jest.spyOn(view.model, 'destroy').mockImplementation(() => Promise.resolve())

    view.render()
    view.openAgain()

    // Trigger form submission
    view.destroyModel()

    expect(destroyModelSpy).toHaveBeenCalled()
  })

  it('validates that an assignment group to move to is selected', () => {
    const view = createView(true, true)
    view.render()

    // Mock validateFormData to return validation error
    jest.spyOn(view, 'validateFormData').mockImplementation(() => ({
      move_assignments_to: [
        {
          type: 'required',
        },
      ],
    }))

    const errors = view.validateFormData({move_assignments_to: ''})

    expect(errors).toEqual({
      move_assignments_to: [
        {
          type: 'required',
        },
      ],
    })
  })

  it('moves assignments to another group', () => {
    const view = createView(true, true)
    const destroyModelSpy = jest.spyOn(view, 'destroyModel')
    jest.spyOn(view.model, 'destroy').mockImplementation(() => Promise.resolve())

    view.render()
    view.openAgain()

    // Set the form data and trigger destroy
    view.$('select').val(2)
    view.destroyModel()

    expect(destroyModelSpy).toHaveBeenCalled()
  })

  it('prevents deleting the last assignment group', () => {
    const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => true)
    const view = createView(true, false)
    const destroyModelSpy = jest.spyOn(view, 'destroyModel')

    view.render()
    view.openAgain()

    expect(alertSpy).toHaveBeenCalled()
    expect(destroyModelSpy).not.toHaveBeenCalled()
  })
})
