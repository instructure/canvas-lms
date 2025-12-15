/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {coursesQuery} from '../courseQuery'
import type {QueryFunctionContext} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('coursesQuery', () => {
  const mockCourse = {id: '1', name: 'Test Course'}
  const signal = new AbortController().signal
  const queryKey: any = ['copy_course', 'course', '1']

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  it('should fetch course data', async () => {
    let capturedPath = ''
    server.use(
      http.get('/api/v1/courses/:courseId', ({request}) => {
        capturedPath = new URL(request.url).pathname
        return HttpResponse.json(mockCourse)
      }),
    )

    const result = await coursesQuery({signal, queryKey} as QueryFunctionContext)

    expect(capturedPath).toBe('/api/v1/courses/1')
    expect(result).toEqual(mockCourse)
  })
})
