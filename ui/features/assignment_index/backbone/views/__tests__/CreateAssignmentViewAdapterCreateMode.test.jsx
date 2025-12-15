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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import CreateAssignmentViewAdapter from '../CreateAssignmentViewAdapter'
import Backbone from '@canvas/backbone'

const buildAssignmentGroup = assignments => {
  const group = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments: [],
  }
  const groups = new AssignmentGroupCollection([group])
  const model = groups.models[0]
  model.get('assignments').reset(assignments)
  return model
}

describe('CreateAssignmentViewAdapter Create Mode', () => {
  let closeHandlerMock

  const renderComponent = (overrides = {}) => {
    const defaultProps = {
      assignment: null,
      assignmentGroup: buildAssignmentGroup([]),
      closeHandler: closeHandlerMock,
      ...overrides,
    }
    return render(<CreateAssignmentViewAdapter {...defaultProps} />)
  }

  beforeEach(() => {
    window.ENV.FLAGS = {new_quizzes_by_default: false}
    window.ENV.PERMISSIONS = {
      manage_assignments_edit: true,
      manage_assignments_delete: true,
      by_assignment_id: {},
    }
    window.ENV.SETTINGS = {suppress_assignments: false}
    closeHandlerMock = vi.fn()
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
  })

  it('adds assignment to assignment group when save is clicked', async () => {
    const ag = buildAssignmentGroup([])
    const saveResponse = {
      id: 1,
      name: 'Test',
      points_possible: 100,
      assignment_group_id: ag.id,
      submission_types: ['online_text_entry'],
    }
    const saveSpy = vi.spyOn(Backbone.Model.prototype, 'save').mockImplementation(function () {
      this.set(saveResponse)
      return Promise.resolve(saveResponse)
    })

    const {getByTestId} = renderComponent({assignmentGroup: ag})
    const user = userEvent.setup({delay: null})

    await user.clear(getByTestId('assignment-name-input'))
    await user.type(getByTestId('assignment-name-input'), 'Test')
    await user.clear(getByTestId('points-input'))
    await user.type(getByTestId('points-input'), '100')

    await user.click(getByTestId('save-button'))
    await waitFor(() => expect(saveSpy).toHaveBeenCalled())

    await waitFor(() => {
      const assignments = ag.get('assignments')
      expect(assignments).toHaveLength(1)
      const savedAssignment = assignments.at(0)
      expect(savedAssignment.get('name')).toBe('Test')
      expect(savedAssignment.get('points_possible')).toBe(100)
      expect(savedAssignment.get('assignment_group_id')).toBe(ag.id)
    })
  })

  it('sets manage_assign_to permission when assignment is saved successfully', async () => {
    const ag = buildAssignmentGroup([])
    const saveResponse = {
      id: 456,
      name: 'Test',
      points_possible: 100,
      assignment_group_id: ag.id,
      submission_types: ['online_text_entry'],
    }
    const saveSpy = vi.spyOn(Backbone.Model.prototype, 'save').mockImplementation(function () {
      this.set(saveResponse)
      return Promise.resolve(saveResponse)
    })

    const {getByTestId} = renderComponent({assignmentGroup: ag})
    const user = userEvent.setup({delay: null})

    await user.clear(getByTestId('assignment-name-input'))
    await user.type(getByTestId('assignment-name-input'), 'Test')
    await user.clear(getByTestId('points-input'))
    await user.type(getByTestId('points-input'), '100')

    await user.click(getByTestId('save-button'))
    await waitFor(() => expect(saveSpy).toHaveBeenCalled())

    await waitFor(() => {
      expect(window.ENV.PERMISSIONS.by_assignment_id[456]).toEqual({
        update: true,
        delete: true,
        manage_assign_to: true,
      })
    })
  })
})
