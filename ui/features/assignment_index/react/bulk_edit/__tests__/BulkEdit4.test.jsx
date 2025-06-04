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
import {render, fireEvent, act, screen} from '@testing-library/react'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import moment from 'moment-timezone'
import fetchMock from 'fetch-mock'
import BulkEdit from '../BulkEdit'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'

const ASSIGNMENTS_ENDPOINT = /api\/v1\/courses\/\d+\/assignments/

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

function restrictedAssignmentResponse() {
  const data = standardAssignmentResponse()
  data[0].all_dates[1].can_edit = false
  data[0].all_dates[1].in_closed_grading_period = true
  data[0].all_dates.push({
    id: 'override_2',
    title: 'blah',
    unlock_at: '2020-03-20T00:00:00Z',
    due_at: '2020-03-21T00:00:00Z',
    lock_at: '2020-03-22T00:00:00Z',
    can_edit: false,
  })
  data[1].can_edit = false
  data[1].all_dates[0].can_edit = false
  data[1].moderated_grading = true
  return data
}

function tooManyDatesResponse() {
  const data = standardAssignmentResponse()
  delete data[1].all_dates
  data[1].all_dates_count = 51

  return data
}

function mockAssignmentsResponse(assignments) {
  fetchMock.once('*', assignments)
  return assignments
}

function mockStandardAssignmentsResponse() {
  return mockAssignmentsResponse(standardAssignmentResponse())
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

  describe('saving data', () => {
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
              due_at: '2020-04-01T14:59:59.999Z', // Time of day was preserved, which was UTC 00:00:00
              unlock_at: assignments[0].all_dates[1].unlock_at,
              lock_at: assignments[0].all_dates[1].lock_at,
            },
          ],
        },
      ])
    })

    it('can save multiple assignments and overrides', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const dueAtDate = '2020-04-01'
      const dueAtMoment = moment.tz(dueAtDate, 'Asia/Tokyo')
      changeAndBlurInput(getAllByLabelText('Due At')[0], dueAtDate)
      changeAndBlurInput(getAllByLabelText('Due At')[1], dueAtDate)
      changeAndBlurInput(getAllByLabelText('Due At')[2], dueAtDate)
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetchMock.calls()[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              base: true,
              due_at: '2020-04-01T14:59:59.999Z', // The UTC time of day was preserved
            },
            {
              id: 'override_1',
              due_at: '2020-04-01T14:59:59.999Z',
            },
          ],
        },
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              due_at: dueAtMoment
                .clone()
                .endOf('day') // new due date gets end of day in the specified TZ
                .toISOString(),
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

    it('invokes defaultDueTime on new dates for due_at', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait({
        defaultDueTime: '16:00:00',
      })
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
              due_at: '2020-04-01T07:00:00.000Z', // 16:00 in Tokyo is 07:00 UTC
              lock_at: moment.tz(lockAtDate, 'Asia/Tokyo').endOf('day').toISOString(),
              unlock_at: null,
            },
          ],
        },
      ])
    })

    it('maintains defaultDueTime on new dates for due_at on blur', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait({
        defaultDueTime: '16:00:00',
      })
      const dueAtInput = getAllByLabelText('Due At')[2]
      const dueAtDate = '2020-04-01'

      changeAndBlurInput(dueAtInput, dueAtDate)
      fireEvent.blur(dueAtInput) // Force blur to trigger handleSelectedDateChange
      expect(dueAtInput.value).toMatch('Wed, Apr 1, 2020, 4:00 PM')
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetchMock.calls()[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              due_at: '2020-04-01T07:00:00.000Z', // 16:00 in Tokyo is 07:00 UTC
              unlock_at: null,
            },
          ],
        },
      ])
    })

    it('does not maintain defaultDueTime on new dates for due_at on blur if time is specified', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait({
        defaultDueTime: '16:00:00',
      })
      const dueAtInput = getAllByLabelText('Due At')[2]
      const dueAtDate = '2020-04-01 11:11'

      changeAndBlurInput(dueAtInput, dueAtDate)
      fireEvent.blur(dueAtInput) // Force blur to trigger handleSelectedDateChange
      expect(dueAtInput.value).toMatch('Wed, Apr 1, 2020, 11:11 AM')
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetchMock.calls()[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              due_at: '2020-04-01T02:11:00.000Z', // 11:11 in Tokyo is 07:00 UTC
              unlock_at: null,
            },
          ],
        },
      ])
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

    it('displays an error if starting the save fails', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-01')
      fetchMock.putOnce(
        /api\/v1\/courses\/\d+\/assignments\/bulk_update/,
        {
          body: {
            errors: [{message: 'something bad happened'}],
          },
          status: 401,
        },
        {
          overwriteRoutes: true,
        },
      )
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(getByText(/something bad happened/)).toBeInTheDocument()
    })

    it('displays an error alert if no dates are edited', async () => {
      await renderBulkEditAndWait()
      const saveButton = await screen.findByText('Save')
      await user.click(saveButton)
      const errorMessage = await screen.findByText('Update at least one date to save changes.')
      expect(errorMessage).toBeInTheDocument()
    })
  })
})
