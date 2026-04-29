/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {paceContextsActions} from '../pace_contexts'
import {
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
  COURSE,
  DEFAULT_STORE_STATE,
  PACE_CONTEXTS_DEFAULT_STATE,
} from '../../__tests__/fixtures'

const server = setupServer()

// Track API calls
let sectionApiCalled = false
let studentApiCalled = false

const dispatch = vi.fn()

describe('Pace contexts actions', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    vi.clearAllMocks()
    server.resetHandlers()
    sectionApiCalled = false
    studentApiCalled = false
  })

  it('fetches section pace contexts', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/pace_contexts', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('type') === 'section') {
          sectionApiCalled = true
          return HttpResponse.json(PACE_CONTEXTS_SECTIONS_RESPONSE)
        }
        return HttpResponse.json({})
      }),
    )
    const thunkedAction: any = paceContextsActions.fetchPaceContexts({
      contextType: 'section',
      page: 1,
    })
    const getState = () => ({
      ...DEFAULT_STORE_STATE,
      paceContexts: PACE_CONTEXTS_DEFAULT_STATE,
    })
    await thunkedAction(dispatch, getState)
    expect(sectionApiCalled).toBe(true)
  })

  it('fetches student pace contexts', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/pace_contexts', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('type') === 'student_enrollment') {
          studentApiCalled = true
          return HttpResponse.json(PACE_CONTEXTS_STUDENTS_RESPONSE)
        }
        return HttpResponse.json({})
      }),
    )
    const thunkedAction: any = paceContextsActions.fetchPaceContexts({
      contextType: 'student_enrollment',
      page: 1,
    })
    const getState = () => ({
      ...DEFAULT_STORE_STATE,
      paceContexts: PACE_CONTEXTS_DEFAULT_STATE,
    })
    await thunkedAction(dispatch, getState)
    expect(studentApiCalled).toBe(true)
  })
})
