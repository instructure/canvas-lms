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

describe('Gradebook > DataLoader > GradingPeriodAssignmentsLoader', () => {
  const url = '/courses/1201/gradebook/grading_period_assignments'

  let exampleData
  let network

  beforeEach(() => {
    exampleData = {
      gradingPeriodAssignments: {1401: ['2301']},
    }
  })

  describe('#loadGradingPeriodAssignments()', () => {
    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    function loadGradingPeriodAssignments() {
      store.getState().fetchGradingPeriodAssignments()
      return network.allRequestsReady()
    }

    function resolveRequest() {
      const [request] = getRequests()
      request.response.setJson({
        grading_period_assignments: exampleData.gradingPeriodAssignments,
      })
      request.response.send()
    }

    function getRequests() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request using the given course id', async () => {
      await loadGradingPeriodAssignments()
      const requests = getRequests()
      expect(requests.length).toStrictEqual(1)
    })

    test('includes the loaded grading period assignments when updating the gradebook', async () => {
      const loaded = await loadGradingPeriodAssignments()
      resolveRequest()
      await loaded
      expect(store.getState().gradingPeriodAssignments).toStrictEqual(
        exampleData.gradingPeriodAssignments
      )
    })
  })
})
