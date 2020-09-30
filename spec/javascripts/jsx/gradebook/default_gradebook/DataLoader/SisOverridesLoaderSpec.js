/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import SisOverridesLoader from 'jsx/gradebook/default_gradebook/DataLoader/SisOverridesLoader'
import {NetworkFake, setPaginationLinkHeader} from 'jsx/shared/network/NetworkFake'
import {RequestDispatch} from 'jsx/shared/network'

/* eslint-disable no-async-promise-executor */
QUnit.module('Gradebook > DataLoader > SisOverridesLoader', () => {
  QUnit.module('#loadOverrides()', hooks => {
    const url = '/api/v1/courses/1201/assignment_groups'

    let dispatch
    let exampleData
    let gradebook
    let network

    hooks.beforeEach(() => {
      const assignments = [
        {
          id: '2301',
          assignment_group_id: '2201',
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
          assignment_group_id: '2202',
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
        ]
      }

      network = new NetworkFake()
      dispatch = new RequestDispatch()

      gradebook = createGradebook({
        context_id: '1201'
      })

      sinon.stub(gradebook, 'addOverridesToPostGradesStore')
    })

    hooks.afterEach(() => {
      network.restore()
    })

    async function loadOverrides() {
      const dataLoader = new SisOverridesLoader({dispatch, gradebook})
      return dataLoader.loadOverrides()
    }

    function getRequests() {
      return network.getRequests(request => request.path === url)
    }

    test('sends a request to the assignment groups url', async () => {
      loadOverrides()
      await network.allRequestsReady()
      const requests = getRequests()
      strictEqual(requests.length, 1)
    })

    test('excludes rubrics when requesting assignments', async () => {
      loadOverrides()
      await network.allRequestsReady()
      const [{params}] = getRequests()
      ok(params.exclude_response_fields.includes('rubric'))
    })

    QUnit.module('when sending the initial request', () => {
      test('excludes "wiki_page" submission types', async () => {
        loadOverrides()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        deepEqual(params.exclude_assignment_submission_types, ['wiki_page'])
      })

      QUnit.module('excluded fields', () => {
        test('includes "description"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.exclude_response_fields.includes('description'))
        })

        test('includes "in_closed_grading_period"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.exclude_response_fields.includes('in_closed_grading_period'))
        })

        test('includes "needs_grading_count"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.exclude_response_fields.includes('needs_grading_count'))
        })
      })

      QUnit.module('"include" parameter', () => {
        test('includes "assignments"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.include.includes('assignments'))
        })

        test('includes "grades_published"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.include.includes('grades_published'))
        })

        test('includes "overrides"', async () => {
          loadOverrides()
          await network.allRequestsReady()
          const [{params}] = getRequests()
          ok(params.include.includes('overrides'))
        })
      })

      test('sets "override_assignment_dates" to false', async () => {
        loadOverrides()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.override_assignment_dates, 'false')
      })
    })

    QUnit.module('when the first page resolves', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadOverrides()
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
      let overridesLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          overridesLoaded = loadOverrides()
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

      test('updates the post grades store in the gradebook', async () => {
        strictEqual(gradebook.addOverridesToPostGradesStore.callCount, 1)
      })

      test('includes the loaded assignment groups when updating the post grades store', async () => {
        const [assignmentGroups] = gradebook.addOverridesToPostGradesStore.lastCall.args
        deepEqual(assignmentGroups, exampleData.assignmentGroups)
      })

      test('resolves the returned promise', async () => {
        equal(await overridesLoaded, null)
      })

      test('resolves the returned promise after updating the post grades store', () => {
        return overridesLoaded.then(() => {
          strictEqual(gradebook.addOverridesToPostGradesStore.callCount, 1)
        })
      })
    })

    QUnit.module('if the first response does not link to the last page', contextHooks => {
      /*
       * This supposes that somehow the pagination links are either not present
       * or have excluded the last page, which is required for pagination
       * cheating to work for Gradebook. /
       */

      let overridesLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          overridesLoaded = loadOverrides()
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
        equal(await overridesLoaded, null)
      })
    })
  })
})
/* eslint-enable no-async-promise-executor */
