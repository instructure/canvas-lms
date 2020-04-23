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

import {clearPrefetchedXHRs, getPrefetchedXHR, setPrefetchedXHR} from '@instructure/js-utils'

import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import StudentIdsLoader from 'jsx/gradebook/default_gradebook/DataLoader/StudentIdsLoader'
import {NetworkFake} from 'jsx/shared/network/NetworkFake'
import {RequestDispatch} from 'jsx/shared/network'

QUnit.module('Gradebook > DataLoader > StudentIdsLoader', suiteHooks => {
  const url = '/courses/1201/gradebook/user_ids'

  let dataLoader
  let dispatch
  let exampleData
  let gradebook
  let network

  suiteHooks.beforeEach(() => {
    exampleData = {
      studentIds: ['1101', '1102', '1103']
    }
  })

  QUnit.module('#loadStudentIds()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()

      gradebook = createGradebook({
        context_id: '1201'
      })

      dataLoader = new StudentIdsLoader({dispatch, gradebook})
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadStudentIds() {
      dataLoader.loadStudentIds()
      return network.allRequestsReady()
    }

    function resolveRequest() {
      const [request] = getRequestsForUserIds()
      request.response.setJson({user_ids: exampleData.studentIds})
      request.response.send()
    }

    function getRequestsForUserIds() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request using the given course id', async () => {
      await loadStudentIds()
      const requests = getRequestsForUserIds()
      strictEqual(requests.length, 1)
    })

    test('stores the loaded student ids in the gradebook', async () => {
      const loaded = await loadStudentIds()
      resolveRequest()
      await loaded
      const loadedStudentIds = gradebook.courseContent.students.listStudentIds()
      deepEqual(loadedStudentIds, exampleData.studentIds)
    })

    QUnit.module('when student ids have been prefetched', contextHooks => {
      contextHooks.beforeEach(() => {
        const jsonString = JSON.stringify({user_ids: exampleData.studentIds})
        const response = new Response(jsonString)
        setPrefetchedXHR('user_ids', Promise.resolve(response))
      })

      contextHooks.afterEach(() => {
        clearPrefetchedXHRs()
      })

      test('does not send a request for student ids', async () => {
        await loadStudentIds()
        const requests = getRequestsForUserIds()
        strictEqual(requests.length, 0)
      })

      test('stores the loaded student ids in the gradebook', async () => {
        await loadStudentIds()
        const loadedStudentIds = gradebook.courseContent.students.listStudentIds()
        deepEqual(loadedStudentIds, exampleData.studentIds)
      })

      test('removes the prefetch request', async () => {
        await loadStudentIds()
        strictEqual(typeof getPrefetchedXHR('user_ids'), 'undefined')
      })
    })
  })
})
