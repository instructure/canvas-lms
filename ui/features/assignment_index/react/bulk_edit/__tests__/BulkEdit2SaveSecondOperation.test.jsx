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
import {render, fireEvent, act, waitFor} from '@testing-library/react'
import {vi} from 'vitest'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import BulkEdit from '../BulkEdit'
import fakeENV from '@canvas/test-utils/fakeENV'

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
      ],
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
  return {...render(<BulkEdit {...props} />), ...props}
}

function changeAndBlurInput(input, newValue) {
  fireEvent.change(input, {target: {value: newValue}})
  fireEvent.blur(input)
}

describe('Assignment Bulk Edit Dates - Second Save Operation', () => {
  let progressCallCount = 0

  const server = setupServer(
    http.get(/\/api\/v1\/courses\/\d+\/assignments/, () => {
      return HttpResponse.json(standardAssignmentResponse())
    }),
    http.put(/\/api\/v1\/courses\/\d+\/assignments\/bulk_update/, () => {
      return HttpResponse.json({url: '/progress'})
    }),
    http.get('/progress', () => {
      progressCallCount++
      // Always return complete immediately for faster tests
      return HttpResponse.json({
        url: '/progress',
        workflow_state: 'complete',
        completion: 100,
      })
    }),
  )

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    progressCallCount = 0
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

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
    tzInTest.restore()
  })

  it('clears success message when making changes after save', async () => {
    const {getByText, queryByText, getAllByLabelText, findAllByLabelText} = renderBulkEdit()

    // Wait for assignments to load by waiting for Due At inputs
    await findAllByLabelText('Due At')

    // Make a change and save
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-01')
    fireEvent.click(getByText('Save'))

    // Wait for first save to complete
    await waitFor(() => {
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    })

    // Make another change - success message should clear
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-02')
    expect(queryByText(/saved successfully/)).toBe(null)
  })

  it('can save again after completing first save', async () => {
    const {getByText, getAllByLabelText, findAllByLabelText} = renderBulkEdit()

    // Wait for assignments to load by waiting for Due At inputs
    await findAllByLabelText('Due At')

    // First save
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-01')
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    })

    const firstSaveProgressCalls = progressCallCount

    // Second save
    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-02')
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      // Progress should be called more times for second save
      expect(progressCallCount).toBeGreaterThan(firstSaveProgressCalls)
      expect(getByText(/saved successfully/)).toBeInTheDocument()
    })
  })
})
