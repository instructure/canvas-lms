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

import {clearPrefetchedXHRs, getPrefetchedXHR, setPrefetchedXHR} from '@instructure/js-utils'
import {NetworkFake} from '@canvas/network/NetworkFake/index'
import store from '../index'

describe('Gradebook > DataLoader > StudentIdsLoader', () => {
  const url = '/courses/1201/gradebook/user_ids'

  let exampleData
  let network

  beforeEach(() => {
    exampleData = {
      studentIds: ['1101', '1102', '1103'],
    }
  })

  describe('#fetchStudentIds()', () => {
    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    function fetchStudentIds() {
      store.getState().fetchStudentIds()
      return network.allRequestsReady()
    }

    function getRequestsForUserIds() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request using the given course id', async () => {
      await fetchStudentIds()
      const requests = getRequestsForUserIds()
      expect(requests.length).toStrictEqual(1)
    })

    describe('when student ids have been prefetched', () => {
      beforeEach(() => {
        const jsonString = JSON.stringify({user_ids: exampleData.studentIds})
        const response = new Response(jsonString)
        setPrefetchedXHR('user_ids', Promise.resolve(response))
      })

      afterEach(() => {
        clearPrefetchedXHRs()
      })

      test('does not send a request for student ids', async () => {
        await fetchStudentIds()
        const requests = getRequestsForUserIds()
        expect(requests.length).toStrictEqual(0)
      })

      test('removes the prefetch request', async () => {
        await fetchStudentIds()
        expect(typeof getPrefetchedXHR('user_ids')).toStrictEqual('undefined')
      })
    })
  })
})
