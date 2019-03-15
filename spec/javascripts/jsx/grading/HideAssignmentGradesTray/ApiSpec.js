/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import MockCanvasClient from '../../../support/MockCanvasClient'
import * as Api from 'jsx/grading/HideAssignmentGradesTray/Api'

QUnit.module('HideAssignmentGradesTray Api', suiteHooks => {
  const ASSIGNMENT_ID = '23'
  const BAD_ASSIGNMENT_ID = '24'
  const PROGRESS_ID = 7331

  suiteHooks.beforeEach(() => {
    MockCanvasClient.install([
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES,
          variables: {assignmentId: ASSIGNMENT_ID}
        },
        result: {
          data: {
            hideAssignmentGrades: {
              __typename: 'hideAssignmentGrades',
              progress: {
                __typename: 'Progress',
                _id: PROGRESS_ID,
                state: 'queued'
              }
            }
          }
        }
      },
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES,
          variables: {assignmentId: BAD_ASSIGNMENT_ID}
        },
        result: {
          data: null,
          errors: [{message: 'a graphql error'}]
        }
      }
    ])
  })

  suiteHooks.afterEach(() => {
    MockCanvasClient.uninstall()
  })

  QUnit.module('.hideAssignmentGrades()', () => {
    test('returns the Progress id', async () => {
      const progress = await Api.hideAssignmentGrades(ASSIGNMENT_ID)
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      deepEqual(progress, expectedProgress)
    })

    test('consumers are required to handle when mutating rejects', async () => {
      try {
        await Api.hideAssignmentGrades(BAD_ASSIGNMENT_ID)
      } catch (error) {
        strictEqual(error.message, 'GraphQL error: a graphql error')
      }
    })
  })

  QUnit.module('.resolveHideAssignmentGradesStatus', contextHooks => {
    let server

    contextHooks.beforeEach(() => {
      server = sinon.createFakeServer()
      server.respondImmediately = true
    })

    contextHooks.afterEach(() => {
      server.restore()
    })

    test('resolves without problem when job finishes', async () => {
      const responseData = {url: `/api/v1/progress/${PROGRESS_ID}`, workflow_state: 'completed'}
      server.respondWith('GET', `/api/v1/progress/${PROGRESS_ID}`, [
        200,
        {},
        JSON.stringify(responseData)
      ])
      await Api.resolveHideAssignmentGradesStatus({id: PROGRESS_ID, workflowState: 'queued'})
      // The code for resolveProgress implies that progress.results is
      // returned when a Progress object completes, but in actual usage, there
      // is no results field in the returned Progress objects. To be faithful
      // to real world usage, I have elected not to assert against a field that
      // is never returned.
      ok(true)
    })

    test('consumers are required to handle when job fails', async () => {
      const responseData = {
        message: 'job failed',
        url: `/api/v1/progress/${PROGRESS_ID}`,
        workflow_state: 'failed'
      }
      server.respondWith('GET', `/api/v1/progress/${PROGRESS_ID}`, [
        200,
        {},
        JSON.stringify(responseData)
      ])

      try {
        await Api.resolveHideAssignmentGradesStatus({id: PROGRESS_ID, workflowState: 'queued'})
      } catch (error) {
        strictEqual(error, 'job failed')
      }
    })
  })
})
