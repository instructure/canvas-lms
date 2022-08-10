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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import AssignmentGroupsLoader from 'ui/features/gradebook/react/default_gradebook/DataLoader/AssignmentGroupsLoader'
import PerformanceControls from 'ui/features/gradebook/react/default_gradebook/PerformanceControls'
import {NetworkFake, setPaginationLinkHeader} from '@canvas/network/NetworkFake/index'
import {RequestDispatch} from '@canvas/network'

/* eslint-disable no-async-promise-executor */
QUnit.module('Gradebook > DataLoader > AssignmentGroupsLoader', suiteHooks => {
  const url = '/api/v1/courses/1201/assignment_groups'

  let dispatch
  let exampleData
  let gradebook
  let network
  let performanceControls
  let requestCharacterLimit

  suiteHooks.beforeEach(() => {
    const assignments = [
      {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: '/courses/1201/assignments/2301',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry']
      },

      {
        id: '2302',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: '/courses/1201/assignments/2302',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry']
      }
    ]

    exampleData = {
      assignmentGroups: [
        {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
        {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
        {id: '2203', position: 3, name: 'Extra Credit', assignments: []}
      ],

      assignments
    }
  })

  QUnit.module('#loadAssignmentGroups()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()
      performanceControls = new PerformanceControls()
      requestCharacterLimit = 8000

      gradebook = createGradebook({
        context_id: '1201'
      })
      sinon.stub(gradebook, 'updateAssignmentGroups')
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadAssignmentGroups() {
      const dataLoader = new AssignmentGroupsLoader({
        dispatch,
        gradebook,
        performanceControls,
        requestCharacterLimit
      })

      return dataLoader.loadAssignmentGroups()
    }

    function getRequests() {
      return network.getRequests(request => request.path === url)
    }

    test('sends a request to the assignment groups url', async () => {
      loadAssignmentGroups()
      await network.allRequestsReady()
      const requests = getRequests()
      strictEqual(requests.length, 1)
    })

    test('excludes rubrics when requesting assignments', async () => {
      loadAssignmentGroups()
      await network.allRequestsReady()
      const [{params}] = getRequests()
      ok(params.exclude_response_fields.includes('rubric'))
    })

    test('includes module ids when requesting assignments if the course has modules', async () => {
      loadAssignmentGroups()
      await network.allRequestsReady()
      const [{params}] = getRequests()
      ok(params.include.includes('module_ids'))
    })

    test('excludes module ids when requesting assignments if the course has no modules', async () => {
      gradebook.options.has_modules = false
      loadAssignmentGroups()
      await network.allRequestsReady()
      const [{params}] = getRequests()
      notOk(params.include.includes('module_ids'))
    })

    QUnit.module('when grading periods are in use', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.gradingPeriodId = '3'
        gradebook.gotGradingPeriodAssignments({
          grading_period_assignments: {
            3: ['1', '8', '12'],
            19: ['4', '77', '99'],
            66: ['3'],
            68: []
          }
        })
      })

      test('makes a single request if "All Grading Periods" is selected', async () => {
        gradebook.gradingPeriodId = '0'
        loadAssignmentGroups()
        await network.allRequestsReady()
        const requests = getRequests()
        strictEqual(requests.length, 1)
      })

      test('makes two requests if a grading period is selected and release flag is enabled', async () => {
        loadAssignmentGroups()
        await network.allRequestsReady()
        const requests = getRequests()
        strictEqual(requests.length, 2)
      })

      test('makes one request if a grading period is selected and too many assignments are being requested', async () => {
        requestCharacterLimit = 5
        loadAssignmentGroups()
        await network.allRequestsReady()
        const requests = getRequests()
        strictEqual(requests.length, 1)
      })

      test('makes one request if a grading period is selected that has no assignments in it', async () => {
        gradebook.gradingPeriodId = '68'
        loadAssignmentGroups()
        await network.allRequestsReady()
        const requests = getRequests()
        strictEqual(requests.length, 1)
      })

      test('makes one request to get assignments for the current grading period', async () => {
        loadAssignmentGroups()
        await network.allRequestsReady()
        const {params} = getRequests()[0]
        strictEqual(params.assignment_ids, '1,8,12')
      })

      test('makes another request to get assignments for all other grading periods', async () => {
        loadAssignmentGroups()
        await network.allRequestsReady()
        const {params} = getRequests()[1]
        strictEqual(params.assignment_ids, '4,77,99,3')
      })

      test('excludes assignments in the second request that were present in the first', async () => {
        gradebook.gotGradingPeriodAssignments({
          grading_period_assignments: {
            3: ['1', '2'],
            19: ['2', '3']
          }
        })
        loadAssignmentGroups()
        await network.allRequestsReady()
        const {params} = getRequests()[1]
        strictEqual(params.assignment_ids, '3')
      })

      test('does not include duplicates in requested assignment ids', async () => {
        gradebook.gotGradingPeriodAssignments({
          grading_period_assignments: {
            3: ['1', '2'],
            19: ['3', '4'],
            22: ['4', '5'],
            89: ['5', '6', '7']
          }
        })
        loadAssignmentGroups()
        await network.allRequestsReady()
        const {params} = getRequests()[1]
        strictEqual(params.assignment_ids, '3,4,5,6,7')
      })
    })

    QUnit.module('when sending the initial request', () => {
      test('sets the `per_page` parameter to the configured per page maximum', async () => {
        performanceControls = new PerformanceControls({assignmentGroupsPerPage: 45})
        loadAssignmentGroups()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.per_page, '45')
      })
    })

    QUnit.module('when the first page resolves', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadAssignmentGroups()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.assignmentGroups.slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('sends a request for each additional page', () => {
        const pages = getRequests()
          .slice(1)
          .map(request => request.params.page)
        deepEqual(pages, ['2', '3'])
      })

      test('uses the same path for each page', () => {
        const [{path}] = getRequests()
        getRequests()
          .slice(1)
          .forEach(request => {
            equal(request.path, path)
          })
      })

      test('uses the same parameters for each page', () => {
        const [{params}] = getRequests()
        getRequests()
          .slice(1)
          .forEach(request => {
            const {page, ...pageParams} = request.params
            deepEqual(pageParams, params)
          })
      })
    })

    QUnit.module('when all pages have resolved', contextHooks => {
      let assignmentGroupsLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          assignmentGroupsLoaded = loadAssignmentGroups()
          await network.allRequestsReady()

          // Resolve the first page
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.assignmentGroups.slice(0, 1))
          response.send()
          await network.allRequestsReady()

          // Resolve the remaining pages
          const [request2, request3] = getRequests().slice(1)
          setPaginationLinkHeader(request2.response, {last: 3})
          request2.response.setJson(exampleData.assignmentGroups.slice(1, 2))
          request2.response.send()

          setPaginationLinkHeader(request3.response, {last: 3})
          request3.response.setJson(exampleData.assignmentGroups.slice(2, 3))
          request3.response.send()

          resolve()
        })
      })

      test('updates the assignment groups in the gradebook', async () => {
        strictEqual(gradebook.updateAssignmentGroups.callCount, 1)
      })

      test('includes the loaded assignment groups when updating the gradebook', async () => {
        const [assignmentGroups] = gradebook.updateAssignmentGroups.lastCall.args
        deepEqual(assignmentGroups, exampleData.assignmentGroups)
      })

      test('resolves the returned promise', async () => {
        equal(await assignmentGroupsLoaded, null)
      })

      test('resolves the returned promise after updating the gradebook', () => {
        return assignmentGroupsLoaded.then(() => {
          strictEqual(gradebook.updateAssignmentGroups.callCount, 1)
        })
      })
    })

    QUnit.module('if the first response does not link to the last page', contextHooks => {
      /*
       * This supposes that somehow the pagination links are either not present
       * or have excluded the last page, which is required for pagination
       * cheating to work for Gradebook. /
       */

      let assignmentGroupsLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          assignmentGroupsLoaded = loadAssignmentGroups()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          response.setJson(exampleData.assignmentGroups.slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('does not send additional requests', () => {
        strictEqual(getRequests().length, 1)
      })

      test('resolves the returned promise', async () => {
        equal(await assignmentGroupsLoaded, null)
      })
    })
  })
})
/* eslint-enable no-async-promise-executor */
