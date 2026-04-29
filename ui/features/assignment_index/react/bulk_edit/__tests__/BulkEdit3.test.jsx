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
import anchorage from 'timezone/America/Anchorage'
import moment from 'moment-timezone'
import fetchMock from 'fetch-mock'
import BulkEdit from '../BulkEdit'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {vi} from 'vitest'

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
        assignments,
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
        assignmentListWithDates(),
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
        assignmentListWithDates(),
      )
      const checkboxes = getAllByLabelText(/Select assignment:/)
      fireEvent.click(getByLabelText('Select all assignments'))
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, true, true, true])
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-20')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-20')
      fireEvent.click(getByText(/^Apply$/))
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, false, false])
    })

    it('selects some assignments from start date to end of time', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates(),
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-03-24') // catches the unlock dates
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, false, true, false])
    })

    it('selects some assignments from beginning of time to end date', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates(),
      )
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-03-22')
      fireEvent.click(getByText(/^Apply$/))
      const checkboxes = getAllByLabelText(/Select assignment:/)
      expect(checkboxes.map(cb => cb.checked)).toEqual([true, true, false, false])
    })

    it('checks unlock date for selection', async () => {
      const {getByText, getByLabelText, getAllByLabelText} = await renderBulkEditAndWait(
        {},
        assignmentListWithDates(),
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
        assignmentListWithDates(),
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
        assignmentListWithDates(),
      )
      changeAndBlurInput(getByLabelText('Selection start date'), '2020-05-15')
      changeAndBlurInput(getByLabelText('Selection end date'), '2020-05-14')
      expect(
        getAllByText('The end date must be after the start date').length,
      ).toBeGreaterThanOrEqual(1)
      expect(getByText(/^Apply$/).closest('button')).toBeDisabled()
    })
  })
})
