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

import MockCanvasClient from '@canvas/test-utils/MockCanvasClient'
import * as Api from '../Api'
import {http} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

describe('HideAssignmentGradesTray Api', () => {
  const ASSIGNMENT_ID = '23'
  const BAD_ASSIGNMENT_ID = '24'
  const PROGRESS_ID = 7331
  const SECTION_IDS = ['2001', '2002', '2003']

  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    MockCanvasClient.install([
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES,
          variables: {assignmentId: ASSIGNMENT_ID},
        },
        result: {
          data: {
            hideAssignmentGrades: {
              __typename: 'hideAssignmentGrades',
              progress: {
                __typename: 'Progress',
                _id: PROGRESS_ID,
                state: 'queued',
              },
            },
          },
        },
      },
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES,
          variables: {assignmentId: BAD_ASSIGNMENT_ID},
        },
        result: {
          data: null,
          errors: [{message: 'a graphql error'}],
        },
      },
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS,
          variables: {assignmentId: ASSIGNMENT_ID, sectionIds: SECTION_IDS},
        },
        result: {
          data: {
            hideAssignmentGradesForSections: {
              __typename: 'hideAssignmentGradesForSections',
              progress: {
                __typename: 'Progress',
                _id: PROGRESS_ID,
                state: 'queued',
              },
            },
          },
        },
      },
      {
        request: {
          query: Api.HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS,
          variables: {assignmentId: BAD_ASSIGNMENT_ID, sectionIds: SECTION_IDS},
        },
        result: {
          data: null,
          errors: [{message: 'a graphql error'}],
        },
      },
    ])
  })

  afterEach(() => {
    MockCanvasClient.uninstall()
    server.resetHandlers()
  })

  describe('.hideAssignmentGrades()', () => {
    it('returns the Progress id', async () => {
      const progress = await Api.hideAssignmentGrades(ASSIGNMENT_ID)
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      expect(progress).toEqual(expectedProgress)
    })

    it('consumers are required to handle when mutating rejects', async () => {
      await expect(Api.hideAssignmentGrades(BAD_ASSIGNMENT_ID)).rejects.toThrow('a graphql error')
    })
  })

  describe('.hideAssignmentGradesForSections()', () => {
    it('returns the Progress', async () => {
      const progress = await Api.hideAssignmentGradesForSections(ASSIGNMENT_ID, SECTION_IDS)
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      expect(progress).toEqual(expectedProgress)
    })

    it('consumers are required to handle when mutating rejects', async () => {
      await expect(
        Api.hideAssignmentGradesForSections(BAD_ASSIGNMENT_ID, SECTION_IDS),
      ).rejects.toThrow('a graphql error')
    })
  })

  describe('.resolveHideAssignmentGradesStatus', () => {
    it('returns ids of submissions hidden when job finishes', async () => {
      const responseData = {
        results: {submission_ids: ['201', '202', '203']},
        url: `/api/v1/progress/${PROGRESS_ID}`,
        workflow_state: 'completed',
      }
      server.use(
        http.get(`/api/v1/progress/${PROGRESS_ID}`, () => {
          return new Response(JSON.stringify(responseData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
      const results = await Api.resolveHideAssignmentGradesStatus({
        id: PROGRESS_ID,
        workflowState: 'queued',
      })
      expect(results.submissionIds).toEqual(['201', '202', '203'])
    })

    it('consumers are required to handle when job fails', async () => {
      const responseData = {
        message: 'job failed',
        url: `/api/v1/progress/${PROGRESS_ID}`,
        workflow_state: 'failed',
      }
      server.use(
        http.get(`/api/v1/progress/${PROGRESS_ID}`, () => {
          return new Response(JSON.stringify(responseData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await expect(
        Api.resolveHideAssignmentGradesStatus({id: PROGRESS_ID, workflowState: 'queued'}),
      ).rejects.toEqual('job failed')
    })
  })
})
