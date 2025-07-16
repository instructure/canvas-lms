// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import store from '../index'

const exampleAssignmentGroup = {
  assignments: [],
  group_weight: 1,
  id: '2',
  name: 'test',
  position: 1,
  sis_source_id: null,
}

describe('Gradebook > store > sisOverrideState', () => {
  const courseId = store.getState().courseId
  const url = `/api/v1/courses/${courseId}/assignment_groups`
  const server = setupServer()
  const capturedRequests: any[] = []

  describe('#fetchSisOverrides()', () => {
    beforeAll(() => {
      server.listen()
    })

    beforeEach(() => {
      capturedRequests.length = 0
    })

    afterEach(() => {
      server.resetHandlers()
    })

    afterAll(() => {
      server.close()
    })

    function getRequests() {
      return capturedRequests.filter(request => request.url.includes('/assignment_groups'))
    }

    test('sends the request', async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          return HttpResponse.json([exampleAssignmentGroup])
        }),
      )

      await store.getState().fetchSisOverrides()
      const requests = getRequests()
      expect(requests).toHaveLength(1)
    })

    test('saves sis overrides to the store', async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          return HttpResponse.json([exampleAssignmentGroup])
        }),
      )

      await store.getState().fetchSisOverrides()
      expect(store.getState().sisOverrides).toStrictEqual([exampleAssignmentGroup])
    })
  })
})
