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

// Because node 10 is dumb and doesn't have this yet
import 'array-flat-polyfill'

// grab this before fake timers replace it
const realSetImmediate = setImmediate
async function flushPromises() {
  await act(() => new Promise(realSetImmediate))
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
          lock_at: '2020-03-21T00:00:00Z',
          can_edit: true
        },
        {
          id: 'override_1',
          title: '2 students',
          unlock_at: '2020-03-29T00:00:00Z',
          due_at: '2020-03-30T00:00:00Z',
          lock_at: '2020-03-31T00:00:00Z',
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
    unlock_at: '2020-03-20T00:00:00Z',
    due_at: '2020-03-21T00:00:00Z',
    lock_at: '2020-03-22T00:00:00Z',
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
    onSave: jest.fn(),
    ...overrides
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

beforeEach(() => {
  jest.useFakeTimers()
  fetch.resetMocks()
})

describe('Assignment Bulk Edit Dates', () => {
  let oldEnv
  let timezoneSnapshot
  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      TIMEZONE: 'Asia/Tokyo',
      FEATURES: {}
    }
    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(tokyo, 'Asia/Tokyo')
  })

  afterEach(async () => {
    await flushPromises()
    window.ENV = oldEnv
    timezone.restore(timezoneSnapshot)
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
    fireEvent.change(getAllByLabelText('Due At')[0], {target: {value: '2020-04-01'}})
    fireEvent.click(getByText('Save'))
    expect(onSave).toHaveBeenCalled()
  }, 10000)

  it('disables save when nothing has been edited', async () => {
    const {getByText} = await renderBulkEditAndWait()
    expect(getByText('Save').closest('button').disabled).toBe(true)
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

  it('modifies unlock date and enables save', async () => {
    const {getByText, getByDisplayValue} = await renderBulkEditAndWait()
    const assignmentUnlockInput = getByDisplayValue('Thu Mar 19, 2020')
    fireEvent.change(assignmentUnlockInput, {target: {value: '2020-01-01'}})
    fireEvent.blur(assignmentUnlockInput)
    expect(assignmentUnlockInput.value).toBe('Wed Jan 1, 2020')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  })

  it('modifies lock at date and enables save', async () => {
    const {getByText, getByDisplayValue} = await renderBulkEditAndWait()
    const overrideLockInput = getByDisplayValue('Tue Mar 31, 2020')
    fireEvent.change(overrideLockInput, {target: {value: '2020-12-31'}})
    fireEvent.blur(overrideLockInput)
    expect(overrideLockInput.value).toBe('Thu Dec 31, 2020')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  })

  it('modifies due date and enables save', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const nullDueDate = getAllByLabelText('Due At')[2]
    fireEvent.change(nullDueDate, {target: {value: '2020-06-15'}})
    fireEvent.blur(nullDueDate)
    expect(nullDueDate.value).toBe('Mon Jun 15, 2020')
    expect(getByText('Save').closest('button').disabled).toBe(false)
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
              due_at: '2020-04-01T00:00:00.000Z', // Time of day was preserved, which was UTC 00:00:00
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
              due_at: '2020-04-01T03:00:00.000Z' // The UTC time of day was preserved
            },
            {
              id: 'override_1',
              due_at: '2020-04-01T00:00:00.000Z'
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
                .endOf('day') // new due date gets end of day in the specified TZ
                .toISOString()
            }
          ]
        }
      ])
    }, 30000) // if this reaches 30 seconds we really need to have a better plan

    it('disables the Save button while saving', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      const overrideDueAtInput = getAllByLabelText('Due At')[1]
      const dueAtDate = '2020-04-01'
      fireEvent.change(overrideDueAtInput, {target: {value: dueAtDate}})
      const saveButton = getByText('Save').closest('button')
      expect(saveButton.disabled).toBe(false)
      fireEvent.click(saveButton)
      expect(saveButton.disabled).toBe(true)
      expect(getByText('Saving...')).toBeInTheDocument()
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

    it('displays an error if starting the save fails', async () => {
      const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
      fireEvent.change(getAllByLabelText('Due At')[0], {target: {value: '2020-04-01'}})
      fetch.mockResponseOnce(JSON.stringify({errors: [{message: 'something bad happened'}]}), {
        status: 401
      })
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(getByText(/something bad happened/)).toBeInTheDocument()
    }, 10000)
  })

  describe('save progress', () => {
    async function renderBulkEditAndSave() {
      const fns = await renderBulkEditAndWait()
      fireEvent.change(fns.getAllByLabelText('Due At')[0], {target: {value: '2020-04-01'}})
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
    }, 10000)

    it('displays an error if the progress fetch fails', async () => {
      const {getByText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(JSON.stringify({errors: [{message: 'could not get progress'}]}), {
        status: 401
      })
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/could not get progress/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(false)
    }, 10000)

    it('displays an error if the job fails', async () => {
      const {getByText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(
        JSON.stringify({
          completion: 42,
          workflow_state: 'failed',
          results: [
            {assignment_id: 'assignment_1', errors: {due_at: [{message: 'some bad dates'}]}}
          ]
        })
      )
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/some bad dates/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(false)
    }, 10000)

    it('can start a second save operation', async () => {
      const {getByText, queryByText, getAllByLabelText} = await renderBulkEditAndSave()
      fetch.mockResponseOnce(
        JSON.stringify({url: 'progress url', workflow_state: 'complete', completion: 100})
      )
      act(jest.runAllTimers)
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
      expect(getByText('Save').closest('button').disabled).toBe(true)

      fireEvent.change(getAllByLabelText('Due At')[0], {target: {value: '2020-04-02'}})
      expect(queryByText(/saved successfully/)).toBe(null)

      fetch.mockResponses(
        [JSON.stringify({url: 'progress url'})],
        [JSON.stringify({url: 'progress url', workflow_state: 'complete', completion: 100})]
      )
      fireEvent.click(getByText('Save'))
      await flushPromises()
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    }, 15000)
  })

  describe('assignment selections', () => {
    beforeEach(() => {
      window.ENV.FEATURES.assignment_bulk_edit_phase_2 = true
    })

    it('displays checkboxes for each main assignment', async () => {
      const {getByText, getAllByText, assignments} = await renderBulkEditAndWait()
      expect(getAllByText('Select assignment')).toHaveLength(assignments.length)
      expect(getByText('0 assignments selected')).toBeInTheDocument()
    })

    it('disables checkboxes for assignments that cannot be edited', async () => {
      const {getAllByLabelText} = await renderBulkEditAndWait({}, restrictedAssignmentResponse())
      expect(getAllByLabelText('Select assignment')[0].disabled).toBe(true)
      expect(getAllByLabelText('Select assignment')[1].disabled).toBe(true)
    })

    it('allows assignments to be checked individually', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait()
      const checkboxes = getAllByLabelText('Select assignment')
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
        all_dates: [{base: true, unlock_at: null, due_at: null, lock_at: null, can_edit: true}]
      })
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignments
      )
      const allCheckbox = getByLabelText('Select all assignments')
      fireEvent.click(allCheckbox)
      const checkboxes = getAllByLabelText('Select assignment')
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

  describe('batch edit dialog', () => {
    async function renderOpenBatchEditDialog(selectAssignments = [0]) {
      const result = await renderBulkEditAndWait()
      selectAssignments.forEach(index => {
        fireEvent.click(result.getAllByLabelText('Select assignment')[index])
      })
      fireEvent.click(result.getByText('Batch Edit'))
      return result
    }

    beforeEach(() => {
      window.ENV.FEATURES.assignment_bulk_edit_phase_2 = true
    })

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
              lock_at: '2020-03-23T00:00:00.000Z'
            },
            {
              id: 'override_1',
              unlock_at: '2020-03-31T00:00:00.000Z',
              due_at: '2020-04-01T00:00:00.000Z',
              lock_at: '2020-04-02T00:00:00.000Z'
            }
          ]
        }
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
              lock_at: assignments[0].all_dates[0].lock_at
            },
            {
              id: 'override_1',
              unlock_at: assignments[0].all_dates[1].unlock_at,
              due_at: null,
              lock_at: assignments[0].all_dates[1].lock_at
            }
          ]
        }
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
              lock_at: null
            },
            {
              id: 'override_1',
              unlock_at: null,
              due_at: assignments[0].all_dates[1].due_at,
              lock_at: null
            }
          ]
        }
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
              lock_at: null
            },
            {
              id: 'override_1',
              unlock_at: null,
              due_at: null,
              lock_at: null
            }
          ]
        }
      ])
    })

    it('disables "Ok" when neither checkbox is selected', async () => {
      const {getByText, getByLabelText} = await renderOpenBatchEditDialog([0])
      fireEvent.click(getByLabelText('Remove Dates'))
      fireEvent.click(getByLabelText('Due Dates'))
      expect(getByText('Ok').closest('button').disabled).toBe(true)
    })
  })

  describe('errors', () => {
    it('dislays error message if lock-at date is before due date', async () => {})
    it('dislays error message if unlock-at date is after due date', async () => {})
    it('dislays error message if any date is after course-end date', async () => {})
    it('dislays error message if any date is before course-start date', async () => {})
    it('dislays error message if any date is before course-term start date', async () => {})
    it('dislays error message if any date is after course-term end date', async () => {})
    it('dislays error message if any date is before user-role term access from', async () => {})
    it('dislays error message if any date is after user-role term access until', async () => {})
  })
})
