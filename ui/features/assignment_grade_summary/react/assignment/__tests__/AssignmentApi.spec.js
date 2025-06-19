/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as AssignmentApi from '../AssignmentApi'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('GradeSummary AssignmentApi', () => {
  const server = setupServer()
  let capturedRequests = []

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    capturedRequests = []
  })
  afterAll(() => server.close())

  describe('.speedGraderUrl()', () => {
    test('returns the SpeedGrader url for the given course, assignment, and student', () => {
      const expected = '/courses/1201/gradebook/speed_grader?assignment_id=2301&student_id=1101'
      const options = {anonymousStudents: false, studentId: '1101'}
      expect(AssignmentApi.speedGraderUrl('1201', '2301', options)).toBe(expected)
    })

    test('optionally uses the anonymous_id key for the student id', () => {
      const expected = '/courses/1201/gradebook/speed_grader?assignment_id=2301&anonymous_id=abcde'
      const options = {anonymousStudents: true, studentId: 'abcde'}
      expect(AssignmentApi.speedGraderUrl('1201', '2301', options)).toBe(expected)
    })
  })

  describe('.releaseGrades()', () => {
    const url = `/api/v1/courses/1201/assignments/2301/provisional_grades/publish`

    test('sends a request to release provisional grades', async () => {
      server.use(
        http.post(url, async ({request}) => {
          capturedRequests.push({url: request.url, method: request.method})
          return HttpResponse.json({})
        }),
      )
      await AssignmentApi.releaseGrades('1201', '2301')
      const request = capturedRequests[0]
      expect(new URL(request.url).pathname).toBe(url)
    })

    test('sends a POST request', async () => {
      server.use(
        http.post(url, async ({request}) => {
          capturedRequests.push({url: request.url, method: request.method})
          return HttpResponse.json({})
        }),
      )
      await AssignmentApi.releaseGrades('1201', '2301')
      const request = capturedRequests[0]
      expect(request.method).toBe('POST')
    })

    test('does not catch failures', async () => {
      server.use(
        http.post(url, () => {
          return HttpResponse.json({error: 'server error'}, {status: 500})
        }),
      )
      try {
        await AssignmentApi.releaseGrades('1201', '2301')
      } catch (e) {
        expect(e.message).toContain('500')
      }
    })
  })

  describe('.unmuteAssignment()', () => {
    const url = `/courses/1201/assignments/2301/mute`

    test('sends a request to unmute the assignment', async () => {
      server.use(
        http.put(url, async ({request}) => {
          capturedRequests.push({url: request.url, method: request.method})
          return HttpResponse.json({})
        }),
      )
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = capturedRequests[0]
      expect(new URL(request.url).pathname).toBe(url)
    })

    test('sets muted status to false', async () => {
      server.use(
        http.put(url, async ({request}) => {
          const requestUrl = new URL(request.url)
          capturedRequests.push({
            url: request.url,
            method: request.method,
            searchParams: requestUrl.searchParams,
          })
          return HttpResponse.json({})
        }),
      )
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = capturedRequests[0]
      expect(request.searchParams.get('status')).toBe('false')
    })

    test('sends a PUT request', async () => {
      server.use(
        http.put(url, async ({request}) => {
          capturedRequests.push({url: request.url, method: request.method})
          return HttpResponse.json({})
        }),
      )
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = capturedRequests[0]
      expect(request.method).toBe('PUT')
    })

    test('does not catch failures', async () => {
      server.use(
        http.put(url, () => {
          return HttpResponse.json({error: 'server error'}, {status: 500})
        }),
      )
      try {
        await AssignmentApi.unmuteAssignment('1201', '2301')
      } catch (e) {
        expect(e.message).toContain('500')
      }
    })
  })
})
