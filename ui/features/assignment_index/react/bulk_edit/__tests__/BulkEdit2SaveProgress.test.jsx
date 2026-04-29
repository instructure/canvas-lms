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
import {render, fireEvent, waitFor, screen} from '@testing-library/react'
import {vi} from 'vitest'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the hook to use a short polling interval for tests
const originalModule = await vi.importActual('../hooks/useMonitorJobCompletion')
vi.mock('../hooks/useMonitorJobCompletion', () => ({
  default: props => originalModule.default({...props, pollingInterval: 10}),
}))

// Import BulkEdit after the mock is set up
const {default: BulkEdit} = await import('../BulkEdit')

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

describe('Assignment Bulk Edit Dates - Save Progress Polling', () => {
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
      // Immediately return completed state for a simple, fast test
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

  it('polls for progress and shows success on completion', async () => {
    const {getByText, getAllByLabelText, findAllByLabelText} = renderBulkEdit()

    await findAllByLabelText('Due At')

    changeAndBlurInput(getAllByLabelText('Due At')[0], '2020-04-01')
    fireEvent.click(getByText('Save'))

    // Wait for success message
    await waitFor(() => {
      expect(screen.getByText(/saved successfully/)).toBeInTheDocument()
    })

    // Button changes to Close on success
    expect(getByText('Close')).toBeInTheDocument()

    // Verify progress endpoint was called
    expect(progressCallCount).toBeGreaterThanOrEqual(1)
  })
})
