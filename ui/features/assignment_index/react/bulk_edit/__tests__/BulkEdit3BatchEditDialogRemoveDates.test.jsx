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

import {fireEvent} from '@testing-library/react'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {vi} from 'vitest'
import {flushPromises, renderOpenBatchEditDialog} from './BulkEditBatchEditDialogTestUtils'

beforeEach(() => {
  fetchMock.put(/api\/v1\/courses\/\d+\/assignments\/bulk_update/, {})
  vi.useFakeTimers()
})

afterEach(() => {
  fetchMock.reset()
  vi.useRealTimers()
})

describe('Assignment Bulk Edit Dates - Remove Dates', () => {
  const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null})

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

  it('removes due dates from assignments', async () => {
    const {assignments, getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
    fireEvent.click(getByLabelText('Remove Dates'))
    await user.click(getByText('Confirm'))
    vi.runAllTimers()
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toHaveLength(1)
    expect(body).toMatchObject([
      {
        id: 'assignment_1',
        all_dates: [
          {
            base: true,
            unlock_at: assignments[0].all_dates[0].unlock_at,
            due_at: null,
            lock_at: assignments[0].all_dates[0].lock_at,
          },
          {
            id: 'override_1',
            unlock_at: assignments[0].all_dates[1].unlock_at,
            due_at: null,
            lock_at: assignments[0].all_dates[1].lock_at,
          },
        ],
      },
    ])
  })

  it('removes availability dates from assignments', async () => {
    const {assignments, getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
    fireEvent.click(getByLabelText('Remove Dates'))
    fireEvent.click(getByLabelText('Remove Availability Dates'))
    await user.click(getByText('Confirm'))
    vi.runAllTimers()
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toHaveLength(1)
    expect(body).toMatchObject([
      {
        id: 'assignment_1',
        all_dates: [
          {
            base: true,
            unlock_at: null,
            due_at: assignments[0].all_dates[0].due_at,
            lock_at: null,
          },
          {
            id: 'override_1',
            unlock_at: null,
            due_at: assignments[0].all_dates[1].due_at,
            lock_at: null,
          },
        ],
      },
    ])
  })

  it('removes all dates from assignments', async () => {
    const {getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
    fireEvent.click(getByLabelText('Remove Dates'))
    fireEvent.click(getByLabelText('Remove Both'))
    await user.click(getByText('Confirm'))
    vi.runAllTimers()
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetchMock.calls()[1][1].body)
    expect(body).toHaveLength(1)
    expect(body).toMatchObject([
      {
        id: 'assignment_1',
        all_dates: [
          {
            base: true,
            unlock_at: null,
            due_at: null,
            lock_at: null,
          },
          {
            id: 'override_1',
            unlock_at: null,
            due_at: null,
            lock_at: null,
          },
        ],
      },
    ])
  })
})
