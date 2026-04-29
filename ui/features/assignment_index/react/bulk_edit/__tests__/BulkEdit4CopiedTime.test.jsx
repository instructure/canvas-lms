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
  vi.useRealTimers()
})

describe('Assignment Bulk Edit Dates - Copied Time Preservation', () => {
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

  it('preserves the copied time when there are no values in the date box', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const unlockAtInput = getAllByLabelText('Available From')[2]
    const unlockDate = 'Wed, Apr 1, 2020, 4:00 PM'
    changeAndBlurInput(unlockAtInput, unlockDate)
    expect(unlockAtInput.value).toMatch('Wed, Apr 1, 2020, 4:00 PM')
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toMatchObject([
      {
        id: 'assignment_2',
        all_dates: [
          {
            base: true,
            unlock_at: '2020-04-01T07:00:00.000Z',
            due_at: null,
            lock_at: null,
          },
        ],
      },
    ])
  })

  it('preserves the copied time when there is an existing value in the date box', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const unlockAtInput = getAllByLabelText('Available From')[2]
    changeAndBlurInput(unlockAtInput, 'Wed, Apr 3, 2020, 4:00 PM')
    const unlockDate = 'Wed, Apr 1, 2020, 1:00 PM'
    changeAndBlurInput(unlockAtInput, unlockDate)
    expect(unlockAtInput.value).toMatch('Wed, Apr 1, 2020, 1:00 PM')
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toMatchObject([
      {
        id: 'assignment_2',
        all_dates: [
          {
            base: true,
            unlock_at: '2020-04-01T04:00:00.000Z',
            due_at: null,
            lock_at: null,
          },
        ],
      },
    ])
  })
})
