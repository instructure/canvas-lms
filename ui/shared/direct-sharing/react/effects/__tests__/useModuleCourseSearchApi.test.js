/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {renderHook} from '@testing-library/react-hooks/dom'
import {waitFor} from '@testing-library/react'
import useModuleCourseSearchApi from '../useModuleCourseSearchApi'

const server = setupServer()

const response = [
  {
    id: '1',
    name: 'Module Fire',
  },
  {
    id: '2',
    name: 'Module Water',
  },
]

describe('useModuleCourseSearchApi', () => {
  let lastRequestUrl

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    lastRequestUrl = undefined
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('fetches and reports results', async () => {
    server.use(
      http.get('/api/v1/courses/1/modules', () => {
        return HttpResponse.json(response)
      }),
    )

    const success = vi.fn()
    const error = vi.fn()
    renderHook(() => useModuleCourseSearchApi({success, params: {contextId: 1}}))
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith([
        expect.objectContaining({id: '1', name: 'Module Fire'}),
        expect.objectContaining({id: '2', name: 'Module Water'}),
      ])
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('passes "per_page" query param on to the xhr call', async () => {
    server.use(
      http.get('/api/v1/courses/1/modules', ({request}) => {
        lastRequestUrl = request.url
        return HttpResponse.json(response)
      }),
    )

    const success = vi.fn()
    renderHook(() => useModuleCourseSearchApi({success, params: {contextId: 1, per_page: 50}}))
    await waitFor(() => {
      expect(lastRequestUrl).toContain('/api/v1/courses/1/modules?per_page=50')
    })
  })
})
