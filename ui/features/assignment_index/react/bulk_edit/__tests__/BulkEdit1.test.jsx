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
      restrictedAssignmentResponse(),
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
    expect(dueDateInputs).toHaveLength(2)

    expect(getByText('This assignment has too many dates to display.')).toBeInTheDocument()
  })
})
