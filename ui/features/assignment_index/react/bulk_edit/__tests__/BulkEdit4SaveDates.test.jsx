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
import moment from 'moment-timezone'
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
  vi.useRealTimers()
})

describe('Assignment Bulk Edit Dates - Save Dates', () => {
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

  it('sets all dates in the set if any one date is edited', async () => {
    const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const overrideDueAtInput = getAllByLabelText('Due At')[1]
    const dueAtDate = '2020-04-01'
    changeAndBlurInput(overrideDueAtInput, dueAtDate)
    fetchMock.putOnce('/api/v1/courses/42/assignments/bulk_update', {})
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const [url, options] = fetchMock.calls()[1]
    expect(url).toBe('/api/v1/courses/42/assignments/bulk_update')
    expect(options.method).toBe('PUT')
    const body = JSON.parse(options.body)
    expect(body).toMatchObject([
      {
        id: 'assignment_1',
        all_dates: [
          {
            due_at: '2020-04-01T14:59:59.999Z',
            unlock_at: assignments[0].all_dates[1].unlock_at,
            lock_at: assignments[0].all_dates[1].lock_at,
          },
        ],
      },
    ])
  })

  it('disables the Save button while saving', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const overrideDueAtInput = getAllByLabelText('Due At')[1]
    const dueAtDate = '2020-04-01'
    changeAndBlurInput(overrideDueAtInput, dueAtDate)
    const saveButton = getByText('Save').closest('button')
    expect(saveButton.disabled).toBe(false)
    fireEvent.click(saveButton)
    expect(saveButton.disabled).toBe(true)
    expect(getByText('Saving...')).toBeInTheDocument()
  })

  it('can clear an existing date', async () => {
    const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const dueAtInput = getAllByLabelText('Due At')[0]
    changeAndBlurInput(dueAtInput, '')
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toMatchObject([
      {
        id: 'assignment_1',
        all_dates: [
          {
            base: true,
            due_at: null,
            unlock_at: assignments[0].all_dates[0].unlock_at,
            lock_at: assignments[0].all_dates[0].lock_at,
          },
        ],
      },
    ])
  })

  it('invokes fancy midnight on new dates for due_at and lock_at', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const dueAtInput = getAllByLabelText('Due At')[2]
    const lockAtInput = getAllByLabelText('Available Until')[2]
    const dueAtDate = '2020-04-01'
    const lockAtDate = '2020-04-02'

    changeAndBlurInput(dueAtInput, dueAtDate)
    changeAndBlurInput(lockAtInput, lockAtDate)
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toMatchObject([
      {
        id: 'assignment_2',
        all_dates: [
          {
            base: true,
            due_at: moment.tz(dueAtDate, 'Asia/Tokyo').endOf('day').toISOString(),
            lock_at: moment.tz(lockAtDate, 'Asia/Tokyo').endOf('day').toISOString(),
            unlock_at: null,
          },
        ],
      },
    ])
  })

  it('applies fancy midnight when reiterating a due date in bulk', async () => {
    const assignments = standardAssignmentResponse()
    assignments[0].all_dates[0].due_at = '2020-02-20T02:59:59Z'
    const {getAllByLabelText} = await renderBulkEditAndWait({}, assignments)
    const dueAtInput = getAllByLabelText('Due At')[0]
    changeAndBlurInput(dueAtInput, '2020-02-20')
    expect(dueAtInput.value).toMatch('Thu, Feb 20, 2020, 11:59 PM')
  })

  it('does not apply fancy midnight when reiterating a due date in bulk if time is specified', async () => {
    const assignments = standardAssignmentResponse()
    assignments[0].all_dates[0].due_at = '2020-02-20T02:59:59Z'
    const {getAllByLabelText} = await renderBulkEditAndWait({}, assignments)
    const dueAtInput = getAllByLabelText('Due At')[0]
    changeAndBlurInput(dueAtInput, '2020-02-20 11:11')
    expect(dueAtInput.value).toMatch('Thu, Feb 20, 2020, 11:11 AM')
  })

  it('invokes beginning of day on new dates for unlock_at', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const unlockAtInput = getAllByLabelText('Available From')[2]
    const unlockDate = '2020-04-01'

    changeAndBlurInput(unlockAtInput, unlockDate)
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toMatchObject([
      {
        id: 'assignment_2',
        all_dates: [
          {
            base: true,
            unlock_at: moment.tz(unlockDate, 'Asia/Tokyo').startOf('day').toISOString(),
            due_at: null,
            lock_at: null,
          },
        ],
      },
    ])
  })
})
