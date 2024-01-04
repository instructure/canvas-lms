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
import tzInTest from '@canvas/datetime/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import anchorage from 'timezone/America/Anchorage'
import moment from 'moment-timezone'
import BulkEdit from '../BulkEdit'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

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
  fetch.mockResponse(JSON.stringify(assignments))
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
  fetch.mockResponseOnce(JSON.stringify(assignments))
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
  jest.useFakeTimers()
  fetch.resetMocks()
})

describe('Assignment Bulk Edit Dates', () => {
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

  it('shows a spinner while loading', async () => {
    mockStandardAssignmentsResponse()
    const {getByText} = renderBulkEdit()
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('invokes onCancel when cancel button is clicked', async () => {
    const {getByText, onCancel} = await renderBulkEditAndWait()
    fireEvent.click(getByText('Cancel'))
    expect(onCancel).toHaveBeenCalled()
  })

  it('invokes onSave when the save button is clicked', async () => {
    const {getByText, getAllByLabelText, onSave} = await renderBulkEditAndWait()
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-01')
    fireEvent.click(getByText('Save'))
    expect(onSave).toHaveBeenCalled()
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
    ENV.HAS_GRADING_PERIODS = true
    ENV.active_grading_periods = [
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

  it('disables save when nothing has been edited', async () => {
    const {getByText} = await renderBulkEditAndWait()
    expect(getByText('Save').closest('button').disabled).toBe(true)
  })

  it('shows the specified dates', async () => {
    const {getAllByLabelText} = await renderBulkEditAndWait()
    const dueDateInputs = getAllByLabelText('Due At')
    expect(dueDateInputs.map(i => i.value)).toEqual([
      'Fri, Mar 20, 2020, 12:00 PM',
      'Mon, Mar 30, 2020, 9:00 AM',
      '',
    ])
    const unlockAtInputs = getAllByLabelText('Available From')
    expect(unlockAtInputs.map(i => i.value)).toEqual([
      'Thu, Mar 19, 2020, 9:00 AM',
      'Sun, Mar 29, 2020, 9:00 AM',
      '',
    ])
    const lockAtInputs = getAllByLabelText('Available Until')
    expect(lockAtInputs.map(i => i.value)).toEqual([
      'Sat, Apr 11, 2020, 9:00 AM',
      'Tue, Apr 21, 2020, 9:00 AM',
      '',
    ])
  })

  it('shows a message and no date default date fields if an assignment does not have default dates', async () => {
    const assignments = standardAssignmentResponse()
    assignments[0].all_dates.shift() // remove the base override
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait({}, assignments)
    expect(getByText('This assignment has no default dates.')).toBeInTheDocument()
    expect(getAllByLabelText('Due At')).toHaveLength(2)
  })

  it('modifies unlock date and enables save', async () => {
    const {getByText, getByDisplayValue} = await renderBulkEditAndWait()
    const assignmentUnlockInput = getByDisplayValue('Thu, Mar 19, 2020, 9:00 AM')
    changeAndBlurInput(assignmentUnlockInput, '2020-01-01')
    expect(assignmentUnlockInput.value).toBe('Wed, Jan 1, 2020, 12:00 AM')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  })

  it('modifies lock at date and enables save', async () => {
    const {getByText, getByDisplayValue} = await renderBulkEditAndWait()
    const overrideLockInput = getByDisplayValue('Tue, Apr 21, 2020, 9:00 AM')
    changeAndBlurInput(overrideLockInput, '2020-12-31')
    expect(overrideLockInput.value).toBe('Thu, Dec 31, 2020, 11:59 PM')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  })

  it('modifies due date and enables save', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const nullDueDate = getAllByLabelText('Due At')[2]
    changeAndBlurInput(nullDueDate, '2020-06-15')
    expect(nullDueDate.value).toBe('Mon, Jun 15, 2020, 11:59 PM')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  })

  it('can blur a field without changes without revert button showing up', async () => {
    const {queryAllByText, getByDisplayValue, getAllByDisplayValue} = await renderBulkEditAndWait()
    const assignmentUnlockAt = getByDisplayValue('Thu, Mar 19, 2020, 9:00 AM')
    fireEvent.blur(assignmentUnlockAt)
    let revertButtons = queryAllByText('Revert date changes').filter(elt => elt.closest('button'))
    expect(revertButtons).toHaveLength(0)

    const nullAssignmentUnlockAt = getAllByDisplayValue('')[0]
    fireEvent.blur(nullAssignmentUnlockAt)
    revertButtons = queryAllByText('Revert date changes').filter(elt => elt.closest('button'))
    expect(revertButtons).toHaveLength(0)
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
    expect(overrideLockInput.value).toBe('Tue, Apr 21, 2020, 9:00 AM') // original value
    expect(assignmentUnlockAt.value).toBe('Mon, Jun 15, 2020, 12:00 AM') // not changed yet
    expect(nullDueDate.value).toBe('Tue, Jun 16, 2020, 11:59 PM') // not changed yet
    // focus should be explicitly set to the lock at input
    expect(document.activeElement).toBe(overrideLockInput)

    fireEvent.click(revertButtons[0])
    fireEvent.click(revertButtons[2])
    expect(assignmentUnlockAt.value).toBe('Thu, Mar 19, 2020, 9:00 AM') // original value
    expect(nullDueDate.value).toBe('') // original value
  })

  it('can revert nonsense input on a row', async () => {
    const {getAllByText, getByDisplayValue} = await renderBulkEditAndWait()
    const assignmentUnlockAt = getByDisplayValue('Thu, Mar 19, 2020, 9:00 AM')
    changeAndBlurInput(assignmentUnlockAt, 'asdf')
    const revertButton = getAllByText('Revert date changes').filter(elt => elt.closest('button'))[0]
    fireEvent.click(revertButton)
    expect(assignmentUnlockAt.value).toBe('Thu, Mar 19, 2020, 9:00 AM') // original value
  })

  it('disables non-editable dates', async () => {
    const {getByTitle, getAllByLabelText} = await renderBulkEditAndWait(
      {},
      restrictedAssignmentResponse()
    )
    const dueDateInputs = getAllByLabelText('Due At')
    expect(dueDateInputs.map(i => i.disabled)).toEqual([false, true, true, true])
    const unlockAtInputs = getAllByLabelText('Available From')
    expect(unlockAtInputs.map(i => i.disabled)).toEqual([false, true, true, true])
    const lockAtInputs = getAllByLabelText('Available Until')
    expect(lockAtInputs.map(i => i.disabled)).toEqual([false, true, true, true])
    expect(getByTitle('In closed grading period')).toBeInTheDocument()
    expect(getByTitle('Only the moderator can edit this assignment')).toBeInTheDocument()
    expect(getByTitle('You do not have permission to edit this assignment')).toBeInTheDocument()
  })

  it('deals with too many dates', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait({}, tooManyDatesResponse())
    const dueDateInputs = getAllByLabelText('Due At')
    expect(dueDateInputs.length).toEqual(2)

    expect(getByText('This assignment has too many dates to display.')).toBeInTheDocument()
  })

  describe('saving data', () => {
    it('sets all dates in the set if any one date is edited', async () => {
      const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const overrideDueAtInput = getAllByLabelText('Due At')[1]
      const dueAtDate = '2020-04-01'
      changeAndBlurInput(overrideDueAtInput, dueAtDate)
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(fetch).toHaveBeenCalledWith(
        '/api/v1/courses/42/assignments/bulk_update',
        expect.objectContaining({
          method: 'PUT',
        })
      )
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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

    it('invokes beginning of day on new dates for unlock_at', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const unlockAtInput = getAllByLabelText('Available From')[2]
      const unlockDate = '2020-04-01'

      changeAndBlurInput(unlockAtInput, unlockDate)
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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

    it('choosing a date from the calendar preserves the time of the existing date in the date input box', async () => {
      const {getAllByText, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const availableAtInput = getAllByLabelText('Available From')[2]
      changeAndBlurInput(availableAtInput, 'Mon, Nov 1, 2021, 4:00 PM')
      fireEvent.click(availableAtInput)
      const button7 = getAllByText('7')[0]
      fireEvent.click(button7)
      expect(availableAtInput.value).toMatch('Sun, Nov 7, 2021, 4:00 PM')
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              unlock_at: '2021-11-07T07:00:00.000Z',
              due_at: null,
              lock_at: null,
            },
          ],
        },
      ])
    })

    it('choosing the same day from the calendar as the existing day in the date input box will preserve the existing time', async () => {
      const {getAllByText, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const availableAtInput = getAllByLabelText('Available From')[2]
      changeAndBlurInput(availableAtInput, 'Mon, Nov 1, 2021, 4:00 PM')
      fireEvent.click(availableAtInput)
      const button7 = getAllByText('1')[0]
      fireEvent.click(button7)
      expect(availableAtInput.value).toMatch('Mon, Nov 1, 2021, 4:00 PM')
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              unlock_at: '2021-11-01T07:00:00.000Z',
              due_at: null,
              lock_at: null,
            },
          ],
        },
      ])
    })

    it('pressing the arrow up key when the calendar is open preserves the time of the existing date in the date input box', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const availableAtInput = getAllByLabelText('Available From')[2]
      changeAndBlurInput(availableAtInput, 'Wed, Nov 3, 2021, 4:00 PM')
      fireEvent.click(availableAtInput)
      fireEvent.keyDown(availableAtInput, {key: 'ArrowUp', keyCode: 38})
      expect(availableAtInput.value).toMatch('Tue, Nov 2, 2021, 4:00 PM')
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              unlock_at: '2021-11-02T07:00:00.000Z',
              due_at: null,
              lock_at: null,
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      const body = JSON.parse(fetch.mock.calls[1][1].body)
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
      fetch.mockResponseOnce(JSON.stringify({errors: [{message: 'something bad happened'}]}), {
        status: 401,
      })
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(getByText(/something bad happened/)).toBeInTheDocument()
    })
  })

  describe('save progress', () => {
    async function renderBulkEditAndSave() {
      const fns = await renderBulkEditAndWait()
      changeAndBlurInput(fns.getAllByLabelText('Due At')[0], '2020-04-01')
      fetch.mockResponses(
        [JSON.stringify({url: 'progress url'})],
        [JSON.stringify({url: 'progress url', workflow_state: 'queued', completion: 0})]
      )
      fireEvent.click(fns.getByText('Save'))
      await flushPromises()
      return fns
    }

    it('polls for progress and updates a progress bar', async () => {
      const {getByText} = await renderBulkEditAndSave()
      expect(fetch).toHaveBeenCalledWith('progress url', expect.anything())
      expect(getByText('0%')).toBeInTheDocument()

      fetch.mockResponses(
        [JSON.stringify({url: 'progress url', workflow_state: 'running', completion: 42})],
        [JSON.stringify({url: 'progress url', workflow_state: 'complete', completion: 100})]
      )

      act(jest.runOnlyPendingTimers)
      await flushPromises()
      expect(getByText('42%')).toBeInTheDocument()

      act(jest.runOnlyPendingTimers)
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(true)
      expect(getByText('Close')).toBeInTheDocument()
      // complete, expect no more polling
      fetch.resetMocks()
      act(jest.runAllTimers)
      await flushPromises()
      expect(fetch).not.toHaveBeenCalled()
    })

    it('displays an error if the progress fetch fails', async () => {
      const {getByText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(JSON.stringify({errors: [{message: 'could not get progress'}]}), {
        status: 401,
      })
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/could not get progress/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(false)
    })

    it('displays an error if the job fails', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(
        JSON.stringify({
          completion: 42,
          workflow_state: 'failed',
          results: [
            {assignment_id: 'assignment_1', errors: {due_at: [{message: 'some bad dates'}]}},
          ],
        })
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

    it('can start a second save operation', async () => {
      const {getByText, queryByText, getAllByLabelText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(
        JSON.stringify({url: 'progress url', workflow_state: 'complete', completion: 100})
      )
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(true)

      changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-02')
      expect(queryByText(/saved successfully/)).toBe(null)

      fetch.mockResponses(
        [JSON.stringify({url: 'progress url'})],
        [JSON.stringify({url: 'progress url', workflow_state: 'complete', completion: 100})]
      )
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    })
  })

  describe('assignment selections', () => {
    it('displays checkboxes for each main assignment', async () => {
      const {getByText, getAllByText, assignments} = await renderBulkEditAndWait()
      expect(getAllByText(/Select assignment:/)).toHaveLength(assignments.length)
      expect(getByText('0 assignments selected')).toBeInTheDocument()
    })

    it('disables checkboxes for assignments that cannot be edited', async () => {
      const {getAllByLabelText} = await renderBulkEditAndWait({}, restrictedAssignmentResponse())
      expect(getAllByLabelText(/Select assignment:/)[0].disabled).toBe(true)
      expect(getAllByLabelText(/Select assignment:/)[1].disabled).toBe(true)
    })

    it('allows assignments to be checked individually', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait()
      const checkboxes = getAllByLabelText(/Select assignment:/)
      fireEvent.click(checkboxes[0])
      expect(checkboxes[0].checked).toBe(true)
      expect(checkboxes[1].checked).toBe(false)
      expect(getByLabelText('Select all assignments').getAttribute('aria-checked')).toBe('mixed')
      expect(getByText('1 assignment selected')).toBeInTheDocument()
    })

    it('selects and deselects all editable assignments with the header', async () => {
      const assignments = restrictedAssignmentResponse()
      assignments.push({
        id: 'assignment_3',
        name: 'third assignment',
        can_edit: true,
        all_dates: [{base: true, unlock_at: null, due_at: null, lock_at: null, can_edit: true}],
      })
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignments
      )
      const allCheckbox = getByLabelText('Select all assignments')
      fireEvent.click(allCheckbox)
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(allCheckbox.checked).toBe(true)
      expect(checkboxes[0].checked).toBe(false)
      expect(checkboxes[1].checked).toBe(false)
      expect(checkboxes[2].checked).toBe(true)
      expect(getByText('1 assignment selected')).toBeInTheDocument()

      fireEvent.click(allCheckbox)
      expect(allCheckbox.checked).toBe(false)
      expect(checkboxes[0].checked).toBe(false)
      expect(checkboxes[1].checked).toBe(false)
      expect(checkboxes[2].checked).toBe(false)
    })
  })

  describe('assignment selection by date', () => {
    function assignmentListWithDates() {
      return [
        {
          id: 'assignment_1',
          name: 'First Assignment',
          can_edit: true,
          all_dates: [
            {
              base: true,
              unlock_at: moment.tz('2020-03-19T00:00:00', 'Asia/Tokyo').toISOString(),
              due_at: moment.tz('2020-03-20T11:59:59', 'Asia/Tokyo').toISOString(),
              lock_at: moment.tz('2020-04-11T11:59:59', 'Asia/Tokyo').toISOString(),
              can_edit: true,
            },
            {
              id: 'override_1',
              title: '2 students',
              unlock_at: moment.tz('2020-03-29T00:00:00', 'Asia/Tokyo').toISOString(),
              due_at: moment.tz('2020-03-30T11:59:59', 'Asia/Tokyo').toISOString(),
              lock_at: moment.tz('2020-04-21T11:59:59', 'Asia/Tokyo').toISOString(),
              can_edit: true,
            },
          ],
        },
        {
          id: 'assignment_2',
          name: 'second assignment',
          can_edit: true,
          all_dates: [
            {
              id: 'override_2',
              unlock_at: moment.tz('2020-03-22T00:00:00', 'Asia/Tokyo').toISOString(),
              due_at: moment.tz('2020-03-23T11:59:59', 'Asia/Tokyo').toISOString(),
              lock_at: null,
              can_edit: true,
            },
          ],
        },
        {
          id: 'assignment_3',
          name: 'third assignment',
          can_edit: true,
          all_dates: [
            {
              base: true,
              unlock_at: moment.tz('2020-03-24T00:00:00', 'Asia/Tokyo').toISOString(),
              due_at: moment.tz('2020-03-25T11:59:59', 'Asia/Tokyo').toISOString(),
              lock_at: null,
              can_edit: true,
            },
          ],
        },
        {
          id: 'assignment_4',
          name: 'fourth assignment',
          can_edit: true,
          all_dates: [
            {
              base: true,
              unlock_at: null,
              due_at: null,
              lock_at: null,
              can_edit: true,
            },
          ],
        },
      ]
    }

    it('apply button is initially disabled when both fields are blank', async () => {
      const {getByText} = await renderBulkEditAndWait()
      expect(getByText(/Apply date range selection/).closest('button').disabled).toBe(true)
    })

    it('apply button is enabled if either field is filled', async () => {
      const {getByText, getByLabelText} = await renderBulkEditAndWait()
      const applyButton = getByText(/Apply date range selection/)
      const startInput = getByLabelText('Selection start date')
      changeAndBlurInput(startInput, '2020-03-18')
      expect(applyButton.closest('button').disabled).toBe(false)
      changeAndBlurInput(startInput, '')
      expect(applyButton.closest('button').disabled).toBe(true)
      const endInput = getByLabelText('Selection end date')
      changeAndBlurInput(endInput, '2020-03-18')
      expect(applyButton.closest('button').disabled).toBe(false)
    })

    it('selects some assignments between two dates', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      const checkboxes = getAllByLabelText(/Select assignment:/)
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-20')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-23')
      fireEvent.click(getByText(/^Apply$/))
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, true, false, false])
    })

    it('deselects assignments outside of the dates', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      const checkboxes = getAllByLabelText(/Select assignment:/)
      checkboxes.forEach(cb => fireEvent.click(cb))
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, true, true, true])
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-20')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-20')
      fireEvent.click(getByText(/^Apply$/))
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, false, false])
    })

    it('selects some assignments from start date to end of time', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-24') // catches the unlock dates
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, true, false])
    })

    it('selects some assignments from beginning of time to end date', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-22')
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, true, false, false])
    })

    it('checks unlock date for selection', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-29')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-29')
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, false, false])
    })

    it('checks lock date for selection', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-04-21')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-04-21')
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, false, false])
    })

    it('shows an error and disables apply if end date is before start date', async () => {
      const {getByText, getByLabelText, getAllByText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates()
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-05-15')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-05-14')
      expect(
        getAllByText('The end date must be after the start date').length
      ).toBeGreaterThanOrEqual(1)
      expect(getByText(/^Apply$/).closest('button')).toBeDisabled()
    })
  })

  describe('batch edit dialog', () => {
    async function renderOpenBatchEditDialog(selectAssignments = [0]) {
      const result = await renderBulkEditAndWait()
      selectAssignments.forEach(index => {
        fireEvent.click(result.getAllByLabelText(/Select assignment:/)[index])
      })
      fireEvent.click(result.getByText('Batch Edit'))
      return result
    }

    it('has a disabled "Batch Edit" button when no assignments are selected', async () => {
      const {getByText, queryByText} = await renderBulkEditAndWait()
      expect(getByText('Batch Edit').closest('button').disabled).toBe(true)
      expect(queryByText('Batch Edit Dates')).toBeNull()
    })

    it('can be canceled with no effects', async () => {
      const {getByText, queryByText, getByTestId} = await renderOpenBatchEditDialog()
      expect(getByText('Batch Edit Dates')).toBeInTheDocument()
      fireEvent.click(getByTestId('cancel-batch-edit'))
      jest.runAllTimers() // required for modal to actually close
      expect(queryByText('Batch Edit Dates')).toBeNull()
      // check no dates edited by disabled save button
      expect(getByText('Save').closest('button').disabled).toBe(true)
    })

    it('shifts dates for all selected assignments forward N days, including overrides', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
      fireEvent.change(getByLabelText('Days'), {target: {value: '2'}})
      fireEvent.click(getByText('Ok'))
      jest.runAllTimers() // required for modal to actually close
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body.length).toBe(1) // second assignment was not selected
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              base: true,
              unlock_at: '2020-03-21T00:00:00.000Z',
              due_at: '2020-03-22T03:00:00.000Z', // time preservation
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
      fireEvent.click(getByText('Ok'))
      jest.runAllTimers() // required for modal to actually close
      // all dates in the assignment are null, so nothing should change
      expect(getByText('Save').closest('button').disabled).toBe(true)
    })

    it('disables "Ok" when N days input is blank', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([1])
      fireEvent.change(getByLabelText('Days'), {target: {value: ''}})
      expect(getByText('Ok').closest('button').disabled).toBe(true)
    })

    it('removes due dates from assignments', async () => {
      const {assignments, getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
      fireEvent.click(getByLabelText('Remove Dates'))
      fireEvent.click(getByText('Ok'))
      jest.runAllTimers() // required for modal to actually close
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body.length).toBe(1) // second assignment was not selected
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
      fireEvent.click(getByLabelText('Due Dates'))
      fireEvent.click(getByLabelText('Availability Dates'))
      fireEvent.click(getByText('Ok'))
      jest.runAllTimers() // required for modal to actually close
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body.length).toBe(1) // second assignment was not selected
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
      fireEvent.click(getByLabelText('Availability Dates'))
      fireEvent.click(getByText('Ok'))
      jest.runAllTimers() // required for modal to actually close
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body.length).toBe(1) // second assignment was not selected
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

    it('disables "Ok" when neither checkbox is selected', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
      fireEvent.click(getByLabelText('Remove Dates'))
      fireEvent.click(getByLabelText('Due Dates'))
      expect(getByText('Ok').closest('button').disabled).toBe(true)
    })
  })
})

describe('in a timezone that does DST', () => {
  let oldEnv
  beforeEach(() => {
    tzInTest.configureAndRestoreLater({
      tz: tz(anchorage, 'America/Anchorage'),
      tzData: {
        'America/Anchorage': anchorage,
      },
    })

    oldEnv = window.ENV
    window.ENV = {
      TIMEZONE: 'America/Anchorage',
      FEATURES: {},
    }
  })

  afterEach(async () => {
    await flushPromises()
    window.ENV = oldEnv
    tzInTest.restore()
  })

  it('preserves the time when shifting to a DST transition day', async () => {
    const af = [
      {
        id: '11',
        name: 'foo',
        can_edit: true,
        all_dates: [
          {
            base: true,
            unlock_at: '2021-11-01T00:00:00Z',
            due_at: '2021-11-02T13:37:14.5Z',
            lock_at: '2022-01-01T00:00:00Z',
            can_edit: true,
          },
        ],
      },
    ]
    const {assignments, getAllByText, getByText, getAllByLabelText} = await renderBulkEditAndWait(
      {},
      af
    )
    const originalDueAtMoment = moment.tz(assignments[0].all_dates[0].due_at, 'America/Anchorage')
    expect(originalDueAtMoment.format('YYYY-MM-DD h:mm:ss.S')).toEqual('2021-11-02 5:37:14.5')
    const dueAtInput = getAllByLabelText('Due At')[0]
    fireEvent.click(dueAtInput)
    const button7 = getAllByText('7')[0]
    fireEvent.click(button7)
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = JSON.parse(fetch.mock.calls[1][1].body)
    const newMoment = moment.tz(body[0].all_dates[0].due_at, 'America/Anchorage')
    expect(newMoment.format('YYYY-MM-DD h:mm:ss.S')).toEqual('2021-11-07 5:37:14.5')
  })
})
