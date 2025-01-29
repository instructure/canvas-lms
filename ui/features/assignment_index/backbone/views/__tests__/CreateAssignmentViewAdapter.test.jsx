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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import CreateAssignmentViewAdapter from '../CreateAssignmentViewAdapter'
import Backbone from '@canvas/backbone'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

const buildAssignment = (options = {}) => ({
  assignment_group_id: 1,
  due_at: null,
  grading_type: 'points',
  points_possible: 5,
  position: 2,
  course_id: 1,
  name: 'Science Quiz',
  submission_types: [],
  html_url: `http://localhost:3000/courses/1/assignments/${options.id}`,
  needs_grading_count: 0,
  all_dates: [],
  published: true,
  ...options,
})

const buildAssignmentOne = () =>
  buildAssignment({
    id: 1,
    name: 'Math Assignment',
    due_at: new Date('2024-04-13').toISOString(),
    points_possible: 10,
    position: 1,
  })

const buildAssignmentGroup = assignments => {
  const group = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments,
  }
  const groups = new AssignmentGroupCollection([group])
  return groups.models[0]
}

describe('CreateAssignmentViewAdapter', () => {
  let closeHandlerMock

  const renderComponent = (overrides = {}) => {
    const defaultProps = {
      assignment: new Assignment(buildAssignmentOne()),
      assignmentGroup: buildAssignmentGroup([]),
      closeHandler: closeHandlerMock,
      ...overrides,
    }
    return render(<CreateAssignmentViewAdapter {...defaultProps} />)
  }

  beforeEach(() => {
    closeHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the CreateEditAssignmentModal', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('create-edit-assignment-modal')).toBeInTheDocument()
  })

  it('calls the closeHandler when the modal is closed', async () => {
    const {getByTestId} = renderComponent()
    const user = userEvent.setup()

    await user.click(getByTestId('close-button'))
    expect(closeHandlerMock).toHaveBeenCalled()
  })

  it('adds assignment to assignment group when save is clicked (Create Mode)', async () => {
    const ag = buildAssignmentGroup([])
    const savePromise = Promise.resolve({})
    const saveSpy = jest
      .spyOn(Backbone.Model.prototype, 'save')
      .mockImplementation(() => savePromise)

    const {getByTestId} = renderComponent({
      assignment: null,
      assignmentGroup: ag,
    })
    const user = userEvent.setup()

    expect(ag.get('assignments')).toHaveLength(0)

    await user.type(getByTestId('assignment-name-input'), 'Test Assignment')
    await user.type(getByTestId('points-input'), '100')
    await user.click(getByTestId('save-button'))

    // Wait for the save operation to complete
    await savePromise
    await new Promise(resolve => setTimeout(resolve, 0)) // Wait for next tick

    expect(ag.get('assignments')).toHaveLength(1)
  })

  it('shows a flash alert when the assignment fails to save', async () => {
    const {getByTestId} = renderComponent()
    const user = userEvent.setup()

    jest.spyOn(Backbone.Model.prototype, 'save').mockRejectedValue(new Error('Failed to save'))

    await user.click(getByTestId('save-button'))

    expect(showFlashAlert).toHaveBeenCalledWith({
      message: expect.any(String),
      type: 'error',
    })
  })
})
