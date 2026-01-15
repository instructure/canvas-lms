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
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import fetchMock from 'fetch-mock'
import BulkEdit from '../BulkEdit'
import fakeENV from '@canvas/test-utils/fakeENV'

const ASSIGNMENTS_ENDPOINT = /api\/v1\/courses\/\d+\/assignments/

const realSetTimeout = setTimeout
async function flushPromises() {
  await act(() => new Promise(realSetTimeout))
}

function standardAssignmentResponse() {
  return [
    {
      id: 'assignment_1',
      name: 'First Assignment',
      can_edit: true,
      all_dates: [
        {
          base: true,
          unlock_at: '2020-03-19T00:00:00Z',
          due_at: '2020-03-20T03:00:00Z',
          lock_at: '2020-04-11T00:00:00Z',
          can_edit: true,
        },
        {
          id: 'override_1',
          title: '2 students',
          unlock_at: '2020-03-29T00:00:00Z',
          due_at: '2020-03-30T00:00:00Z',
          lock_at: '2020-04-21T00:00:00Z',
          can_edit: true,
        },
      ],
    },
    {
      id: 'assignment_2',
      name: 'second assignment',
      can_edit: true,
      all_dates: [{base: true, unlock_at: null, due_at: null, lock_at: null, can_edit: true}],
    },
  ]
}

function renderBulkEdit(overrides = {}) {
  const props = {
    courseId: '42',
    onCancel: vi.fn(),
    onSave: vi.fn(),
    ...overrides,
  }
  const result = {...render(<BulkEdit {...props} />), ...props}
  return result
}

async function renderBulkEditAndWait(overrides = {}, assignments = standardAssignmentResponse()) {
  fetchMock.getOnce(ASSIGNMENTS_ENDPOINT, assignments)
  const result = renderBulkEdit(overrides)
  await flushPromises()
  result.assignments = assignments
  return result
}

function changeAndBlurInput(input, newValue) {
  fireEvent.change(input, {target: {value: newValue}})
  fireEvent.blur(input)
}

beforeEach(() => {
  fetchMock.put(/api\/v1\/courses\/\d+\/assignments\/bulk_update/, {})
  vi.useFakeTimers()
})

afterEach(() => {
  fetchMock.reset()
})

describe('Assignment Bulk Edit Dates - Validation', () => {
  beforeEach(() => {
    fakeENV.setup({
      TIMEZONE: 'Asia/Tokyo',
      FEATURES: {},
    })
    tzInTest.configureAndRestoreLater({
      tz: tz(tokyo, 'Asia/Tokyo'),
      tzData: {
        'Asia/Tokyo': tokyo,
      },
    })
  })

  afterEach(async () => {
    await flushPromises()
    fakeENV.teardown()
    tzInTest.restore()
  })

  it('disables save when local validation fails', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2019-04-01')
    expect(getByText('Unlock date cannot be after due date')).toBeInTheDocument()
    expect(getByText('Save').closest('button').disabled).toBe(true)
  })

  it('clears the validation error when a bad edit is reverted', async () => {
    const {queryByText, getAllByText, getAllByLabelText} = await renderBulkEditAndWait()
    const theInput = getAllByLabelText('Due At')[0]
    changeAndBlurInput(theInput, '2019-04-01')
    expect(queryByText('Unlock date cannot be after due date')).toBeInTheDocument()
    const revertButtons = getAllByText('Revert date changes').filter(elt => elt.closest('button'))
    expect(revertButtons).toHaveLength(1)
    fireEvent.click(revertButtons[0])
    expect(queryByText('Unlock date cannot be after due date')).not.toBeInTheDocument()
  })

  it('validates against closed grading periods', async () => {
    window.ENV.HAS_GRADING_PERIODS = true
    window.ENV.current_user_is_admin = false
    window.ENV.active_grading_periods = [
      {
        start_date: '1970-01-01T00:00:00-07:00',
        end_date: '2020-03-01T23:59:59-07:00',
        close_date: '2020-03-01T23:59:59-07:00',
        id: '1',
        is_closed: true,
        is_last: false,
        permissions: {read: true, create: false, update: false, delete: false},
        title: 'Closed',
      },
      {
        start_date: '2020-03-01T23:59:59-06:00',
        close_date: '3000-12-31T23:59:59-07:00',
        end_date: '3000-12-31T23:59:59-07:00',
        id: '2',
        is_closed: false,
        is_last: true,
        permissions: {read: true, create: false, update: false, delete: false},
        title: '5ever',
      },
    ]
    const {queryByText, getAllByLabelText} = await renderBulkEditAndWait()
    changeAndBlurInput(getAllByLabelText('Available From')[0], '2020-01-01')
    const theInput = getAllByLabelText('Due At')[0]
    changeAndBlurInput(theInput, '2020-03-03')
    expect(queryByText(/Please enter a due date on or after/)).not.toBeInTheDocument()
    changeAndBlurInput(theInput, '2020-01-03')
    expect(queryByText(/Please enter a due date on or after/)).toBeInTheDocument()
  })

  it('can revert edited dates on a row', async () => {
    const {getAllByText, getAllByLabelText, getByDisplayValue} = await renderBulkEditAndWait()

    const assignmentUnlockAt = getByDisplayValue('Thu, Mar 19, 2020, 9:00 AM')
    changeAndBlurInput(assignmentUnlockAt, '2020-06-15')

    const overrideLockInput = getByDisplayValue('Tue, Apr 21, 2020, 9:00 AM')
    changeAndBlurInput(overrideLockInput, '')

    const nullDueDate = getAllByLabelText('Due At')[2]
    changeAndBlurInput(nullDueDate, '2020-06-16')

    const revertButtons = getAllByText('Revert date changes').filter(elt => elt.closest('button'))
    expect(revertButtons).toHaveLength(3)

    fireEvent.click(revertButtons[1])
    expect(overrideLockInput.value).toBe('Tue, Apr 21, 2020, 9:00 AM')
    expect(assignmentUnlockAt.value).toBe('Mon, Jun 15, 2020, 12:00 AM')
    expect(nullDueDate.value).toBe('Tue, Jun 16, 2020, 11:59 PM')
    expect(document.activeElement).toBe(overrideLockInput)

    fireEvent.click(revertButtons[0])
    fireEvent.click(revertButtons[2])
    expect(assignmentUnlockAt.value).toBe('Thu, Mar 19, 2020, 9:00 AM')
    expect(nullDueDate.value).toBe('')
  }, 10000)
})
