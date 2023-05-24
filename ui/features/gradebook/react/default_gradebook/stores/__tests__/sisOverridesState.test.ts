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

import {NetworkFake} from '@canvas/network/NetworkFake/index'
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

  let network

  describe('#fetchSisOverrides()', () => {
    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    function resolveRequest() {
      const [request] = getRequests()
      request.response.setJson([exampleAssignmentGroup])
      request.response.send()
    }

    function getRequests() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request', async () => {
      store.getState().fetchSisOverrides()
      await network.allRequestsReady()
      const requests = getRequests()
      expect(requests.length).toStrictEqual(1)
    })

    test('saves sis overrides to the store', async () => {
      const promise = store.getState().fetchSisOverrides()
      await network.allRequestsReady()
      resolveRequest()
      await promise
      expect(store.getState().sisOverrides).toStrictEqual([exampleAssignmentGroup])
    })
  })
})
