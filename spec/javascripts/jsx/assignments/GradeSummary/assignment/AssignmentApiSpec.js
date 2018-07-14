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

import * as AssignmentApi from 'jsx/assignments/GradeSummary/assignment/AssignmentApi'
import FakeServer, {paramsFromRequest, pathFromRequest} from 'jsx/__tests__/FakeServer'

QUnit.module('GradeSummary AssignmentApi', suiteHooks => {
  let qunitTimeout
  let server

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // avoid accidental unresolved async
    server = new FakeServer()
  })

  suiteHooks.afterEach(() => {
    server.teardown()
    QUnit.config.testTimeout = qunitTimeout
  })

  QUnit.module('.publishGrades()', () => {
    const url = `/api/v1/courses/1201/assignments/2301/provisional_grades/publish`

    test('sends a request to publish provisional grades', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.publishGrades('1201', '2301')
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), url)
    })

    test('sends a POST request', async () => {
      server.for(url).respond({status: 200, body: {}})
      await AssignmentApi.publishGrades('1201', '2301')
      const request = server.receivedRequests[0]
      equal(request.method, 'POST')
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      try {
        await AssignmentApi.publishGrades('1201', '2301')
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
