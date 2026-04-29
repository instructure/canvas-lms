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
import moment from 'moment-timezone'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import BulkEdit from '../BulkEdit'

const ASSIGNMENTS_ENDPOINT = /api\/v1\/courses\/\d+\/assignments/
const BULK_UPDATE_ENDPOINT = /api\/v1\/courses\/\d+\/assignments\/bulk_update/

// Track captured requests for assertions
let capturedRequests = []

const server = setupServer(
  http.get(ASSIGNMENTS_ENDPOINT, () => {
    return HttpResponse.json([])
  }),
  http.put(BULK_UPDATE_ENDPOINT, async ({request}) => {
    const body = await request.json()
    capturedRequests.push({url: request.url, body})
    return HttpResponse.json({})
  }),
)

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
  server.use(
    http.get(ASSIGNMENTS_ENDPOINT, () => {
      return HttpResponse.json(assignments)
    }),
  )
  const result = renderBulkEdit(overrides)
  await flushPromises()
  result.assignments = assignments
  return result
}

function changeAndBlurInput(input, newValue) {
  fireEvent.change(input, {target: {value: newValue}})
  fireEvent.blur(input)
}

beforeAll(() => server.listen())

beforeEach(() => {
  capturedRequests = []
  // Note: This test file intentionally does NOT use fake timers
  // because changing multiple inputs with fake timers can cause timeouts
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => server.close())

describe('Assignment Bulk Edit - Save Multiple', () => {
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

  it('can save multiple assignments and overrides', async () => {
    const {getByText, getAllByLabelText} = await renderBulkEditAndWait()
    const dueAtDate = '2020-04-01'
    const dueAtMoment = moment.tz(dueAtDate, 'Asia/Tokyo')
    changeAndBlurInput(getAllByLabelText('Due At')[0], dueAtDate)
    changeAndBlurInput(getAllByLabelText('Due At')[1], dueAtDate)
    changeAndBlurInput(getAllByLabelText('Due At')[2], dueAtDate)
    fireEvent.click(getByText('Save'))
    await flushPromises()
    const body = capturedRequests[0].body
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
})
