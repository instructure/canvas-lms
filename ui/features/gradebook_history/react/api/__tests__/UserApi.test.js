/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import UserApi from '../UserApi'

const server = setupServer()

let courseId
let requestedUrls = []
let requestedParams = []

describe('UserApi', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    requestedUrls = []
    requestedParams = []
  })
  afterAll(() => server.close())

  beforeEach(() => {
    courseId = 525600
    server.use(
      http.get('*', ({request}) => {
        const url = new URL(request.url)
        requestedUrls.push(url.pathname)
        const params = {}
        url.searchParams.forEach((value, key) => {
          if (key.endsWith('[]')) {
            const cleanKey = key.slice(0, -2)
            if (!params[cleanKey]) params[cleanKey] = []
            params[cleanKey].push(value)
          } else {
            params[key] = value
          }
        })
        // Handle enrollment_state if it's not in the URL but should be empty array
        if (!('enrollment_state' in params) && url.searchParams.has('enrollment_type[]')) {
          params.enrollment_state = []
        }
        requestedParams.push(params)
        return HttpResponse.json({response: {}})
      }),
    )
  })

  test('getUsersByName for graders searches by teachers and TAs in a course', async function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`

    await UserApi.getUsersByName(courseId, 'graders', searchTerm)

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe(url)
    expect(requestedParams[0]).toEqual({
      search_term: searchTerm,
      enrollment_type: ['teacher', 'ta'],
      enrollment_state: [],
    })
  })

  test('getUsersByName for students searches by students', async function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`

    await UserApi.getUsersByName(courseId, 'students', searchTerm)

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe(url)
    expect(requestedParams[0]).toEqual({
      search_term: searchTerm,
      enrollment_type: ['student', 'student_view'],
      enrollment_state: [],
    })
  })

  test('getUsersByName restricts results by enrollment state if specified', async function () {
    const searchTerm = 'Norval'
    const enrollmentState = ['completed']
    const url = `/api/v1/courses/${courseId}/users`

    await UserApi.getUsersByName(courseId, 'students', searchTerm, ['completed'])

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe(url)
    expect(requestedParams[0]).toEqual({
      search_term: searchTerm,
      enrollment_type: ['student', 'student_view'],
      enrollment_state: enrollmentState,
    })
  })

  test('getUsersByName does not restrict results by enrollment state if argument omitted', async function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`

    await UserApi.getUsersByName(courseId, 'students', searchTerm)

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe(url)
    expect(requestedParams[0]).toEqual({
      search_term: searchTerm,
      enrollment_type: ['student', 'student_view'],
      enrollment_state: [],
    })
  })

  test('getUsersByName does not restrict results by enrollment state if passed an empty array', async function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`

    await UserApi.getUsersByName(courseId, 'students', searchTerm, [])

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe(url)
    expect(requestedParams[0]).toEqual({
      search_term: searchTerm,
      enrollment_type: ['student', 'student_view'],
      enrollment_state: [],
    })
  })

  test('getUsersNextPage makes a request with given url', async function () {
    const url = 'https://example.com/users?page=2'

    await UserApi.getUsersNextPage(url)

    expect(requestedUrls).toHaveLength(1)
    expect(requestedUrls[0]).toBe('/users')
  })
})
