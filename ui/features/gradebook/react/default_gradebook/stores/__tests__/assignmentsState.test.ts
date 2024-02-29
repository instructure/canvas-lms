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
import sinon from 'sinon'

describe('Gradebook > DataLoader > GradingPeriodAssignmentsLoader', () => {
  const gradingPeriodAssignmentsUrl = '/courses/1201/gradebook/grading_period_assignments'
  const assignmentGroupsUrl = '/api/v1/courses/1201/assignment_groups'

  let exampleData
  let network

  beforeEach(() => {
    exampleData = {
      gradingPeriodAssignments: {1401: ['2301']},
      assignmentGroups: [
        {
          id: '2301',
          name: 'Assignments',
          position: 1,
          group_weight: 100,
          rules: {},
          assignments: [
            {
              id: '2401',
              name: 'Math Assignment',
              points_possible: 10,
              submission_types: ['online_text_entry'],
              muted: false,
              html_url: 'http://www.example.com/courses/1201/assignments/2401',
              due_at: '2015-05-18T06:59:00Z',
              assignment_group_id: '2301',
              omit_from_final_grade: false,
              published: true,
            },
          ],
        },
      ],
    }
  })

  describe('#loadGradingPeriodAssignments()', () => {
    let clock

    beforeEach(() => {
      clock = sinon.useFakeTimers()
      network = new NetworkFake()
    })

    afterEach(() => {
      clock.restore()
      network.restore()
    })

    function getGradingPeriodRequests() {
      return network.getRequests(request => {
        return request.url.includes(gradingPeriodAssignmentsUrl)
      })
    }

    function getAssignmentGroupRequests() {
      return network.getRequests(request => {
        return request.url.includes(assignmentGroupsUrl)
      })
    }

    function loadGradingPeriodAssignments() {
      store.getState().fetchGradingPeriodAssignments()
      return network.allRequestsReady()
    }

    function loadAssignmentGroups() {
      const loaded = store.getState().loadAssignmentGroups()
      const requestsReady = network.allRequestsReady()
      return [loaded, requestsReady]
    }

    function resolveGradingPeriodRequest() {
      const [request] = getGradingPeriodRequests()
      request.response.setJson({
        grading_period_assignments: exampleData.gradingPeriodAssignments,
      })
      request.response.send()
      clock.tick()
    }

    function resolveAssignmentGroupRequest() {
      const [request] = getAssignmentGroupRequests()
      request.response.setJson(exampleData.assignmentGroups)
      request.response.send()
      clock.tick()
    }

    test('sends the request using the given course id', async () => {
      await loadGradingPeriodAssignments()
      const requests = getGradingPeriodRequests()
      expect(requests.length).toStrictEqual(1)
    })

    test('includes the loaded grading period assignments when updating the gradebook', async () => {
      const loaded = await loadGradingPeriodAssignments()
      resolveGradingPeriodRequest()
      await loaded
      expect(store.getState().gradingPeriodAssignments).toStrictEqual(
        exampleData.gradingPeriodAssignments
      )
    })

    test('loads assignment groups', async () => {
      const [loaded, requestsReady] = await loadAssignmentGroups()
      resolveAssignmentGroupRequest()
      await loaded
      await requestsReady
      expect(store.getState().assignmentGroups).toStrictEqual(exampleData.assignmentGroups)
    })
  })
})
