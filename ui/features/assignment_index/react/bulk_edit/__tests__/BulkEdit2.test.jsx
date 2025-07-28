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
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'

const BULK_EDIT_ENDPOINT = /api\/v1\/courses\/\d+\/assignments\/bulk_update/
const ASSIGNMENTS_ENDPOINT = /api\/v1\/courses\/\d+\/assignments/
const PROGRESS_ENDPOINT = /progress/

// grab this before fake timers replace it
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
    onCancel: jest.fn(),
    onSave: jest.fn(),
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
  jest.useFakeTimers()
})

afterEach(() => {
  fetchMock.reset()
})

describe('Assignment Bulk Edit Dates', () => {
  const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null})
  let oldEnv
  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      TIMEZONE: 'Asia/Tokyo',
      FEATURES: {},
    }
    tzInTest.configureAndRestoreLater({
      tz: tz(tokyo, 'Asia/Tokyo'),
      tzData: {
        'Asia/Tokyo': tokyo,
      },
    })
  })

  afterEach(async () => {
    await flushPromises()
    window.ENV = oldEnv
    tzInTest.restore()
  })

  describe('save progress', () => {
    async function renderBulkEditAndSave() {
      const fns = await renderBulkEditAndWait()
      changeAndBlurInput(fns.getAllByLabelText('Due At')[0], '2020-04-01')
      fetchMock
        .putOnce(
          /api\/v1\/courses\/\d+\/assignments\/bulk_update/,
          {url: 'progress'},
          {overwriteRoutes: true},
        )
        .get(/progress/, {
          url: 'progress',
          workflow_state: 'queued',
          completion: 0,
        })
      fireEvent.click(fns.getByText('Save'))
      await flushPromises()
      return fns
    }

    // fickle
    it.skip('polls for progress and updates a progress bar', async () => {
      const {getByText} = await renderBulkEditAndSave()
      const [url] = fetchMock.calls()[2]
      expect(url).toBe('/progress')
      expect(getByText('0%')).toBeInTheDocument()

      fetchMock.getOnce(
        PROGRESS_ENDPOINT,
        {
          url: '/progress',
          workflow_state: 'running',
          completion: 42,
        },
        {
          overwriteRoutes: true,
        },
      )

      act(jest.runOnlyPendingTimers)
      await flushPromises()
      expect(getByText('42%')).toBeInTheDocument()

      fetchMock.getOnce(
        PROGRESS_ENDPOINT,
        {
          url: '/progress',
          workflow_state: 'complete',
          completion: 100,
        },
        {
          overwriteRoutes: true,
        },
      )

      act(jest.runOnlyPendingTimers)
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
      expect(getByText('Close')).toBeInTheDocument()
      // complete, expect no more polling
      fetchMock.resetHistory()
      act(jest.runAllTimers)
      await flushPromises()
      expect(fetchMock.calls()).toHaveLength(0)
    })

    // fickle
    it.skip('displays an error if the progress fetch fails', async () => {
      const {getByText} = await renderBulkEditAndSave()
      fetchMock.get(
        /progress/,
        {
          body: {errors: [{message: 'could not get progress'}]},
          status: 401,
        },
        {
          overwriteRoutes: true,
        },
      )
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/could not get progress/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(false)
    })

    // fickle
    it.skip('displays an error if the job fails', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndSave()
      fetchMock.get(
        /progress/,
        {
          completion: 42,
          workflow_state: 'failed',
          results: [
            {assignment_id: 'assignment_1', errors: {due_at: [{message: 'some bad dates'}]}},
          ],
        },
        {
          overwriteRoutes: true,
        },
      )
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/some bad dates/)).toBeInTheDocument()
      // save button is disabled due to error
      expect(getByText('Save').closest('button').disabled).toBe(true)
      // fix the error and save should be re-enabled
      changeAndBlurInput(getAllByLabelText(/Due At/)[0], '2020-04-04')
      expect(getByText('Save').closest('button').disabled).toBe(false)
    })

    // fickle
    it.skip('can start a second save operation', async () => {
      // First save operation
      const {getByText, queryByText, getAllByLabelText} = await renderBulkEditAndSave()

      // Mock the progress response for the first save
      fetchMock.get(
        PROGRESS_ENDPOINT,
        {
          url: 'progress',
          workflow_state: 'complete',
          completion: 100,
        },
        {
          overwriteRoutes: true,
        },
      )

      // Run only pending timers to avoid infinite loops
      act(() => jest.runOnlyPendingTimers())
      await flushPromises()

      // Verify first save completed successfully
      expect(getByText(/saved successfully/)).toBeInTheDocument()

      // Make a change to trigger a second save
      changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-02')
      await flushPromises()

      // Success message should be gone after making changes
      expect(queryByText(/saved successfully/)).toBe(null)

      // Set up mocks for the second save operation
      fetchMock.resetHistory()
      fetchMock.putOnce(BULK_EDIT_ENDPOINT, {url: 'progress url'}, {overwriteRoutes: true})

      // Pre-configure all expected network requests for the second save operation
      // This ensures we don't miss any mocks that could cause hanging promises
      fetchMock.get(
        PROGRESS_ENDPOINT,
        {
          url: 'progress url',
          workflow_state: 'complete',
          completion: 100,
        },
        {overwriteRoutes: true},
      )

      // Trigger the second save
      fireEvent.click(getByText('Save'))
      await flushPromises()

      // Run only pending timers to avoid infinite loops
      act(() => jest.runOnlyPendingTimers())
      await flushPromises()

      // Verify second save completed successfully
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    })
  })
})
