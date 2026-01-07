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
import {vi} from 'vitest'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import fetchMock from 'fetch-mock'
import BulkEdit from '../BulkEdit'
import fakeENV from '@canvas/test-utils/fakeENV'

const BULK_EDIT_ENDPOINT = /api\/v1\/courses\/\d+\/assignments\/bulk_update/
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
})

describe('Assignment Bulk Edit Dates - Save Progress Errors', () => {
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

  async function renderBulkEditAndSave() {
    const fns = await renderBulkEditAndWait()
    changeAndBlurInput(fns.getAllByLabelText('Due At')[0], '2020-04-01')
    fetchMock
      .putOnce(BULK_EDIT_ENDPOINT, {url: 'progress'}, {overwriteRoutes: true})
      .get(/progress/, {
        url: 'progress',
        workflow_state: 'queued',
        completion: 0,
      })
    fireEvent.click(fns.getByText('Save'))
    await flushPromises()
    return fns
  }

  it('displays an error if the progress fetch fails', async () => {
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
    act(vi.runAllTimers)
    await flushPromises()
    expect(getByText(/could not get progress/)).toBeInTheDocument()
    expect(getByText('Save').closest('button').disabled).toBe(false)
  }, 20000)

  it('displays an error if the job fails', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndSave()
    fetchMock.get(
      /progress/,
      {
        completion: 42,
        workflow_state: 'failed',
        results: [{assignment_id: 'assignment_1', errors: {due_at: [{message: 'some bad dates'}]}}],
      },
      {
        overwriteRoutes: true,
      },
    )
    act(vi.runAllTimers)
    await flushPromises()
    expect(getByText(/some bad dates/)).toBeInTheDocument()
    // save button is disabled due to error
    expect(getByText('Save').closest('button').disabled).toBe(true)
    // fix the error and save should be re-enabled
    changeAndBlurInput(getAllByLabelText(/Due At/)[0], '2020-04-04')
    expect(getByText('Save').closest('button').disabled).toBe(false)
  }, 20000)
})
