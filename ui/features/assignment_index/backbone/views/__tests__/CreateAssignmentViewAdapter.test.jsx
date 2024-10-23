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
import {fireEvent, render} from '@testing-library/react'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import CreateAssignmentViewAdapter from '../CreateAssignmentViewAdapter'
import Backbone from '@canvas/backbone'
import { act } from 'react-dom/test-utils'

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
    due_at: new Date('April 13, 2024').toISOString(),
    points_possible: 10,
    position: 1,
  })

const buildAssignmentGroup = (assignments) => {
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

  const getProps = (overrides) => ({
    assignment: new Assignment(buildAssignmentOne()),
    assignmentGroup: buildAssignmentGroup([]),
    closeHandler: closeHandlerMock,
    ...overrides,
  })

  beforeEach(() => {
    closeHandlerMock = jest.fn()
  })

  it('renders the CreateEditAssignmentModal', () => {
    const {getByTestId} = render(<CreateAssignmentViewAdapter {...getProps()} />)
    expect(getByTestId('create-edit-assignment-modal')).toBeInTheDocument()
  })

  it('calls the closeHandler when the modal is closed', () => {
    const {getByTestId} = render(<CreateAssignmentViewAdapter {...getProps()} />)

    fireEvent.click(getByTestId('close-button'))
    expect(closeHandlerMock).toHaveBeenCalled()
  })

  it('adds assignment to assignment group when save is clicked (Create Mode)', async () => {
    const ag = buildAssignmentGroup([])

    // Mock out the save method so we can test the assignment group
    jest.spyOn(Backbone.Model.prototype, 'save').mockImplementation(() => Promise.resolve())

    const {getByTestId} = render(<CreateAssignmentViewAdapter {...getProps({assignment: null, assignmentGroup: ag})} />)

    expect(ag.get('assignments').length).toBe(0)

    await act(async () => {
      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})
      fireEvent.click(getByTestId('save-button'))
    })

    expect(ag.get('assignments').length).toBe(1)
  })

  it('renders a FlashAlert when the assignment fails to save', async () => {
    const {getByTestId} = render(<CreateAssignmentViewAdapter {...getProps()} />)

    jest.spyOn(Backbone.Model.prototype, 'save').mockImplementation(() => Promise.reject(new Error('Failed to save')))

    await act(async () => {
      fireEvent.click(getByTestId('save-button'))
    })

    expect(showFlashAlert).toHaveBeenCalled()
  })
})
