/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'
import BulkEdit from '../BulkEdit'

async function flushPromises() {
  await act(() => new Promise(resolve => setTimeout(resolve, 0)))
}

function mockStandardAssignmentsResponse() {
  const assignments = standardAssignmentResponse()
  fetch.mockResponse(JSON.stringify(assignments))
  return assignments
}

function standardAssignmentResponse() {
  return [
    {
      id: 'assignment_1',
      name: 'First Assignment',
      all_dates: [
        {
          base: true,
          unlock_at: '2020-03-19',
          due_at: '2020-03-20',
          lock_at: '2020-03-21'
        },
        {
          id: 'override_1',
          title: '2 students',
          unlock_at: '2020-03-29',
          due_at: '2020-03-30',
          lock_at: '2020-03-31'
        }
      ]
    },
    {
      id: 'assignment_2',
      name: 'second assignment',
      all_dates: [{base: true, unlock_at: null, due_at: null, lock_at: null}]
    }
  ]
}

function renderBulkEdit(overrides = {}) {
  const props = {
    courseId: '42',
    onCancel: jest.fn(),
    ...overrides
  }
  const result = {...render(<BulkEdit {...props} />), ...props}
  return result
}

async function renderBulkEditAndWait(overrides = {}, assignments = standardAssignmentResponse()) {
  fetch.mockResponse(JSON.stringify(assignments))
  const result = renderBulkEdit(overrides)
  await flushPromises()
  return result
}

beforeEach(() => fetch.resetMocks())

describe('Assignment Bulk Edit Dates', () => {
  it('shows a spinner while loading', async () => {
    mockStandardAssignmentsResponse()
    const {getByText} = renderBulkEdit()
    expect(getByText('Loading')).toBeInTheDocument()
    await flushPromises()
  })

  it('invokes onCancel when cancel button is clicked', async () => {
    const {getByText, onCancel} = await renderBulkEditAndWait()
    fireEvent.click(getByText('Cancel'))
    expect(onCancel).toHaveBeenCalled()
  })

  it('shows the specified dates', async () => {
    const {getAllByLabelText} = await renderBulkEditAndWait()
    const dueDateInputs = getAllByLabelText('Due At')
    expect(dueDateInputs.map(i => i.value)).toEqual(['Fri Mar 20, 2020', 'Mon Mar 30, 2020', ''])
    const unlockAtInputs = getAllByLabelText('Available From')
    expect(unlockAtInputs.map(i => i.value)).toEqual(['Thu Mar 19, 2020', 'Sun Mar 29, 2020', ''])
    const lockAtInputs = getAllByLabelText('Available Until')
    expect(lockAtInputs.map(i => i.value)).toEqual(['Sat Mar 21, 2020', 'Tue Mar 31, 2020', ''])
  })

  it('modifies unlock date', async () => {
    const {getByDisplayValue} = await renderBulkEditAndWait()
    const assignmentUnlockInput = getByDisplayValue('Thu Mar 19, 2020')
    fireEvent.change(assignmentUnlockInput, {target: {value: '2020-01-01'}})
    fireEvent.blur(assignmentUnlockInput)
    expect(assignmentUnlockInput.value).toBe('Wed Jan 1, 2020')
  })

  it('modifies lock at date', async () => {
    const {getByDisplayValue} = await renderBulkEditAndWait()
    const overrideLockInput = getByDisplayValue('Tue Mar 31, 2020')
    fireEvent.change(overrideLockInput, {target: {value: '2020-12-31'}})
    fireEvent.blur(overrideLockInput)
    expect(overrideLockInput.value).toBe('Thu Dec 31, 2020')
  })

  it('modifies due date', async () => {
    const {getAllByLabelText} = await renderBulkEditAndWait()
    const nullDueDate = getAllByLabelText('Due At')[2]
    fireEvent.change(nullDueDate, {target: {value: '2020-06-15'}})
    fireEvent.blur(nullDueDate)
    expect(nullDueDate.value).toBe('Mon Jun 15, 2020')
  })
})
