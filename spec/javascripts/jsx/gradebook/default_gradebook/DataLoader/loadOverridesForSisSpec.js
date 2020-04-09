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

import waitForCondition from 'jsx/shared/__tests__/waitForCondition'
import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import FakeServer, {paramsFromRequest} from 'jsx/shared/network/__tests__/FakeServer'

QUnit.module('Gradebook > DataLoader', () => {
  QUnit.module('#loadOverridesForSIS()', hooks => {
    const url = '/api/v1/courses/1201/assignment_groups'

    let dataLoader
    let exampleData
    let gradebook
    let server

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

      server = new FakeServer()

      server.for(url).respond([
        {status: 200, body: [exampleData.assignmentGroups[0]]},
        {status: 200, body: [exampleData.assignmentGroups[1]]},
        {status: 200, body: [exampleData.assignmentGroups[2]]}
      ])

      gradebook = createGradebook({
        context_id: '1201'
      })

      dataLoader = gradebook.dataLoader

      sinon.stub(gradebook, 'addOverridesToPostGradesStore')
    })

    hooks.afterEach(() => {
      server.teardown()
    })

    async function loadOverridesForSIS() {
      dataLoader.loadOverridesForSIS()

      await waitForCondition(() =>
        server.receivedRequests.every(request => Boolean(request.status))
      )
    }

    test('requests all pages of assignment groups using the given course id', async () => {
      await loadOverridesForSIS()
      const requests = server.filterRequests(url)
      strictEqual(requests.length, 3)
    })

    QUnit.module('with each request', () => {
      test('excludes "wiki_page" submission types', async () => {
        await loadOverridesForSIS()
        server.filterRequests(url).forEach(request => {
          const params = paramsFromRequest(request)
          deepEqual(params.exclude_assignment_submission_types, ['wiki_page'])
        })
      })

      QUnit.module('excluded fields', () => {
        test('includes "description"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.exclude_response_fields.includes('description'))
          })
        })

        test('includes "in_closed_grading_period"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.exclude_response_fields.includes('in_closed_grading_period'))
          })
        })

        test('includes "needs_grading_count"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.exclude_response_fields.includes('needs_grading_count'))
          })
        })
      })

      QUnit.module('"include" parameter', () => {
        test('includes "assignments"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.include.includes('assignments'))
          })
        })

        test('includes "grades_published"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.include.includes('grades_published'))
          })
        })

        test('includes "overrides"', async () => {
          await loadOverridesForSIS()
          server.filterRequests(url).forEach(request => {
            const params = paramsFromRequest(request)
            ok(params.include.includes('overrides'))
          })
        })
      })

      test('sets "override_assignment_dates" to false', async () => {
        await loadOverridesForSIS()
        server.filterRequests(url).forEach(request => {
          const params = paramsFromRequest(request)
          strictEqual(params.override_assignment_dates, 'false')
        })
      })
    })

    QUnit.module('when all assignment groups have loaded', () => {
      test('updates the post grades store in the gradebook', async () => {
        await loadOverridesForSIS()
        strictEqual(gradebook.addOverridesToPostGradesStore.callCount, 1)
      })

      test('includes the assignment groups when updating the post grades store', async () => {
        await loadOverridesForSIS()
        const [assignmentGroups] = gradebook.addOverridesToPostGradesStore.lastCall.args
        deepEqual(assignmentGroups, exampleData.assignmentGroups)
      })
    })
  })
})
