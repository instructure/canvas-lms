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

import * as AssignmentApi from 'ui/features/assignment_grade_summary/react/assignment/AssignmentApi'
import FakeServer, {
  paramsFromRequest,
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'

QUnit.module('GradeSummary AssignmentApi', suiteHooks => {
  let server

  suiteHooks.beforeEach(() => {
    server = new FakeServer()
  })

  suiteHooks.afterEach(() => {
    server.teardown()
  })

  QUnit.module('.speedGraderUrl()', () => {
    test('returns the SpeedGrader url for the given course, assignment, and student', () => {
      const expected = '/courses/1201/gradebook/speed_grader?assignment_id=2301&student_id=1101'
      const options = {anonymousStudents: false, studentId: '1101'}
      equal(AssignmentApi.speedGraderUrl('1201', '2301', options), expected)
    })

    test('optionally uses the anonymous_id key for the student id', () => {
      const expected = '/courses/1201/gradebook/speed_grader?assignment_id=2301&anonymous_id=abcde'
      const options = {anonymousStudents: true, studentId: 'abcde'}
      equal(AssignmentApi.speedGraderUrl('1201', '2301', options), expected)
    })
  })

  QUnit.module('.releaseGrades()', () => {
    const url = `/api/v1/courses/1201/assignments/2301/provisional_grades/publish`

    test('sends a request to release provisional grades', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.releaseGrades('1201', '2301')
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), url)
    })

    test('sends a POST request', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.releaseGrades('1201', '2301')
      const request = server.receivedRequests[0]
      equal(request.method, 'POST')
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      try {
        await AssignmentApi.releaseGrades('1201', '2301')
      } catch (e) {
        ok(e.message.includes('500'))
      }
    })
  })

  QUnit.module('.unmuteAssignment()', () => {
    const url = `/courses/1201/assignments/2301/mute`

    test('sends a request to unmute the assignment', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), url)
    })

    test('sets muted status to false', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = server.receivedRequests[0]
      equal(paramsFromRequest(request).status, 'false')
    })

    test('sends a PUT request', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.unmuteAssignment('1201', '2301')
      const request = server.receivedRequests[0]
      equal(request.method, 'PUT')
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      try {
        await AssignmentApi.unmuteAssignment('1201', '2301')
      } catch (e) {
        ok(e.message.includes('500'))
      }
    })
  })
})
