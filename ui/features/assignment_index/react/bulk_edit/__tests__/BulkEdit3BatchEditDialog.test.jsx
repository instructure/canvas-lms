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

import {fireEvent, screen} from '@testing-library/react'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {vi} from 'vitest'
import {
  flushPromises,
  renderBulkEditAndWait,
  renderOpenBatchEditDialog,
} from './BulkEditBatchEditDialogTestUtils'

beforeEach(() => {
  fetchMock.put(/api\/v1\/courses\/\d+\/assignments\/bulk_update/, {})
  vi.useFakeTimers()
})

afterEach(() => {
  fetchMock.reset()
  vi.useRealTimers()
})

describe('Assignment Bulk Edit Dates - Batch Edit Dialog', () => {
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

  describe('Basic Dialog', () => {
    it('displays an error alert if no assignments are selected', async () => {
      await renderBulkEditAndWait()
      const batchEditButton = await screen.findByText('Batch Edit')
      await user.click(batchEditButton)
      const errorMessage = await screen.findByText(
        'Use checkboxes to select one or more assignments to batch edit.',
      )
      expect(errorMessage).toBeInTheDocument()
    })

    it('can be canceled with no effects', async () => {
      const {getByText, queryByText, getByTestId} = await renderOpenBatchEditDialog()
      expect(getByText('Batch Edit Dates')).toBeInTheDocument()
      fireEvent.click(getByTestId('cancel-batch-edit'))
      vi.runAllTimers()
      expect(queryByText('Batch Edit Dates')).toBeNull()
    })

    it('clears days error when closing and reopening the dialog', async () => {
      const {queryByText, getByLabelText, getByTestId} = await renderOpenBatchEditDialog([1])
      fireEvent.change(getByLabelText('Days'), {target: {value: ''}})
      await user.click(queryByText('Confirm'))
      expect(queryByText('Number of days is required')).toBeInTheDocument()

      fireEvent.click(getByTestId('cancel-batch-edit'))
      vi.runAllTimers()

      fireEvent.click(queryByText('Batch Edit'))
      expect(queryByText('Batch Edit Dates')).toBeInTheDocument()
      expect(queryByText('Number of days is required')).not.toBeInTheDocument()
    })
  })

  describe('Shift Dates', () => {
    it('shifts dates for all selected assignments forward N days, including overrides', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
      fireEvent.change(getByLabelText('Days'), {target: {value: '2'}})
      fireEvent.click(getByText('Confirm'))
      vi.runAllTimers()
      await user.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetchMock.calls()[1][1].body)
      expect(body).toHaveLength(1)
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              base: true,
              unlock_at: '2020-03-21T00:00:00.000Z',
              due_at: '2020-03-22T03:00:00.000Z',
              lock_at: '2020-04-13T00:00:00.000Z',
            },
            {
              id: 'override_1',
              unlock_at: '2020-03-31T00:00:00.000Z',
              due_at: '2020-04-01T00:00:00.000Z',
              lock_at: '2020-04-23T00:00:00.000Z',
            },
          ],
        },
      ])
    })

    it('ignores blank date fields', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([1])
      fireEvent.change(getByLabelText('Days'), {target: {value: '2'}})
      fireEvent.click(getByText('Confirm'))
      vi.runAllTimers()
      await user.click(getByText('Save'))
      expect(getByText('Update at least one date to save changes.')).toBeInTheDocument()
    })
  })

  describe('Remove Dates', () => {
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
})
