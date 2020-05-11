/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import GradingPeriodAssignmentsLoader from 'jsx/gradebook/default_gradebook/DataLoader/GradingPeriodAssignmentsLoader'
import {NetworkFake} from 'jsx/shared/network/NetworkFake'
import {RequestDispatch} from 'jsx/shared/network'

QUnit.module('Gradebook > DataLoader > GradingPeriodAssignmentsLoader', suiteHooks => {
  const url = '/courses/1201/gradebook/grading_period_assignments'

  let dataLoader
  let dispatch
  let exampleData
  let gradebook
  let network

  suiteHooks.beforeEach(() => {
    exampleData = {
      gradingPeriodAssignments: {1401: ['2301']}
    }
  })

  QUnit.module('#loadGradingPeriodAssignments()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()

      gradebook = createGradebook({
        context_id: '1201'
      })
      sinon.stub(gradebook, 'updateGradingPeriodAssignments')

      dataLoader = new GradingPeriodAssignmentsLoader({dispatch, gradebook})
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadGradingPeriodAssignments() {
      dataLoader.loadGradingPeriodAssignments()
      return network.allRequestsReady()
    }

    function resolveRequest() {
      const [request] = getRequests()
      request.response.setJson({
        grading_period_assignments: exampleData.gradingPeriodAssignments
      })
      request.response.send()
    }

    function getRequests() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request using the given course id', async () => {
      await loadGradingPeriodAssignments()
      const requests = getRequests()
      strictEqual(requests.length, 1)
    })

    test('updates the grading period assignments in the gradebook', async () => {
      const loaded = await loadGradingPeriodAssignments()
      resolveRequest()
      await loaded
      strictEqual(gradebook.updateGradingPeriodAssignments.callCount, 1)
    })

    test('includes the loaded grading period assignments when updating the gradebook', async () => {
      const loaded = await loadGradingPeriodAssignments()
      resolveRequest()
      await loaded
      const [gradingPeriodAssignments] = gradebook.updateGradingPeriodAssignments.lastCall.args
      deepEqual(gradingPeriodAssignments, exampleData.gradingPeriodAssignments)
    })
  })
})
