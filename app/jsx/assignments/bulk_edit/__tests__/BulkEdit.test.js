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
import timezone from 'timezone_core'
import tokyo from 'timezone/Asia/Tokyo'
import moment from 'moment-timezone'
import BulkEdit from '../BulkEdit'

async function flushPromises() {
  await act(() => new Promise(resolve => setTimeout(resolve, 0)))
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
          unlock_at: '2020-03-19',
          due_at: '2020-03-20T03:00:00Z',
          lock_at: '2020-03-21',
          can_edit: true
        },
        {
          id: 'override_1',
          title: '2 students',
          unlock_at: '2020-03-29',
          due_at: '2020-03-30',
          lock_at: '2020-03-31',
          can_edit: true
        }
      ]
    },
    {
      id: 'assignment_2',
      name: 'second assignment',
      can_edit: true,
      all_dates: [{base: true, unlock_at: null, due_at: null, lock_at: null, can_edit: true}]
    }
  ]
}

function restrictedAssignmentResponse() {
  const data = standardAssignmentResponse()
  data[0].all_dates[1].can_edit = false
  data[0].all_dates[1].in_closed_grading_period = true
  data[0].all_dates.push({
    id: 'override_2',
    title: 'blah',
    unlock_at: '2020-03-20',
    due_at: '2020-03-21',
    lock_at: '2020-03-22',
    can_edit: false
  })
  data[1].can_edit = false
  data[1].all_dates[0].can_edit = false
  data[1].moderated_grading = true
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
    ...overrides
  }
  const result = {...render(<BulkEdit {...props} />), ...props}
  return result
}

async function renderBulkEditAndWait(overrides = {}, assignments = standardAssignmentResponse()) {
  fetch.mockResponse(JSON.stringify(assignments))
  const result = renderBulkEdit(overrides)
  await flushPromises()
  result.assignments = assignments
  return result
}

beforeEach(() => fetch.resetMocks())

describe('Assignment Bulk Edit Dates', () => {
  let oldEnv
  let timezoneSnapshot
  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      TIMEZONE: 'Asia/Tokyo'
    }
    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(tokyo, 'Asia/Tokyo')
  })

  afterEach(() => {
    window.ENV = oldEnv
    timezone.restore(timezoneSnapshot)
  })

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

  it('shows a message and no date default date fields if an assignment does not have default dates', async () => {
    const assignments = standardAssignmentResponse()
    assignments[0].all_dates.shift() // remove the base override
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait({}, assignments)
    expect(getByText('This assignment has no default dates.')).toBeInTheDocument()
    expect(getAllByLabelText('Due At')).toHaveLength(2)
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

  describe('saving data', () => {
    it('sets all dates in the set if any one date is edited', async () => {
      const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const overrideDueAtInput = getAllByLabelText('Due At')[1]
      const dueAtDate = '2020-04-01'
      fireEvent.change(overrideDueAtInput, {target: {value: dueAtDate}})
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(fetch).toHaveBeenCalledWith(
        '/api/v1/courses/42/assignments/bulk_update',
        expect.objectContaining({
          method: 'PUT'
        })
      )
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              due_at: moment.tz(dueAtDate, 'Asia/Tokyo').toISOString(),
              unlock_at: assignments[0].all_dates[1].unlock_at,
              lock_at: assignments[0].all_dates[1].lock_at
            }
          ]
        }
      ])
    }, 10000)

    it('can save multiple assignments and overrides', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const dueAtDate = '2020-04-01'
      const dueAtMoment = moment.tz(dueAtDate, 'Asia/Tokyo')
      fireEvent.change(getAllByLabelText('Due At')[0], {target: {value: dueAtDate}})
      fireEvent.change(getAllByLabelText('Due At')[1], {target: {value: dueAtDate}})
      fireEvent.change(getAllByLabelText('Due At')[2], {target: {value: dueAtDate}})
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              base: true,
              due_at: dueAtMoment
                .clone()
                .add(12, 'hours') // time preservation
                .toISOString()
            },
            {
              id: 'override_1',
              due_at: dueAtMoment.toISOString()
            }
          ]
        },
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              due_at: dueAtMoment
                .clone()
                .endOf('day') // new due date
                .toISOString()
            }
          ]
        }
      ])
    }, 10000)

    it('renders a spinner and disables the Save button while saving', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const overrideDueAtInput = getAllByLabelText('Due At')[1]
      const dueAtDate = '2020-04-01'
      fireEvent.change(overrideDueAtInput, {target: {value: dueAtDate}})
      const saveButton = getByText('Save').closest('button')
      expect(saveButton.getAttribute('disabled')).toBe(null)
      fireEvent.click(saveButton)
      expect(saveButton.getAttribute('disabled')).toBe('')
      expect(getByText('Saving Dates')).toBeInTheDocument()
      await flushPromises()
    }, 10000)

    it('can clear an existing date', async () => {
      const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const dueAtInput = getAllByLabelText('Due At')[0]
      fireEvent.change(dueAtInput, {target: {value: ''}})
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
              lock_at: assignments[0].all_dates[0].lock_at
            }
          ]
        }
      ])
    }, 10000)

    it('invokes fancy midnight on new dates for due_at and lock_at', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const dueAtInput = getAllByLabelText('Due At')[2]
      const lockAtInput = getAllByLabelText('Available Until')[2]
      const dueAtDate = '2020-04-01'
      const lockAtDate = '2020-04-02'

      fireEvent.change(dueAtInput, {target: {value: dueAtDate}})
      fireEvent.change(lockAtInput, {target: {value: lockAtDate}})
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              due_at: moment
                .tz(dueAtDate, 'Asia/Tokyo')
                .endOf('day')
                .toISOString(),
              lock_at: moment
                .tz(lockAtDate, 'Asia/Tokyo')
                .endOf('day')
                .toISOString(),
              unlock_at: null
            }
          ]
        }
      ])
    }, 10000)

    it('invokes beginning of day on new dates for unlock_at', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const unlockAtInput = getAllByLabelText('Available From')[2]
      const unlockDate = '2020-04-01'

      fireEvent.change(unlockAtInput, {target: {value: unlockDate}})
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_2',
          all_dates: [
            {
              base: true,
              unlock_at: moment
                .tz(unlockDate, 'Asia/Tokyo')
                .startOf('day')
                .toISOString(),
              due_at: null,
              lock_at: null
            }
          ]
        }
      ])
    }, 10000)

    it('preserves the existing time on existing dates', async () => {
      const {assignments, getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const dueAtInput = getAllByLabelText('Due At')[0]
      const dueAtDate = '2020-04-01'
      const originalDueAtMoment = moment.tz(assignments[0].all_dates[0].due_at, 'Asia/Tokyo')
      const localTimeOffset = originalDueAtMoment.diff(originalDueAtMoment.clone().startOf('day'))
      fireEvent.change(dueAtInput, {target: {value: dueAtDate}})
      fireEvent.click(getByText('Save'))
      await flushPromises()
      const body = JSON.parse(fetch.mock.calls[1][1].body)
      expect(body).toMatchObject([
        {
          id: 'assignment_1',
          all_dates: [
            {
              base: true,
              due_at: moment
                .tz(dueAtDate, 'Asia/Tokyo')
                .add(localTimeOffset, 'ms')
                .toISOString()
            }
          ]
        }
      ])
    }, 10000)
  })
})
