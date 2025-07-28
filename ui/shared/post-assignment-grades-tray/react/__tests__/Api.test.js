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

const deepEqual = (x, y) => expect(x).toEqual(y)
const strictEqual = (x, y) => expect(x).toBe(y)

describe('PostAssignmentGradesTray Api', () => {
  const ASSIGNMENT_ID = '23'
  const BAD_ASSIGNMENT_ID = '24'
  const PROGRESS_ID = 7331
  const SECTION_IDS = ['2001', '2002', '2003']

  beforeEach(() => {
    MockCanvasClient.install([
      {
        request: {
          query: Api.POST_ASSIGNMENT_GRADES,
          variables: {assignmentId: ASSIGNMENT_ID, gradedOnly: false},
        },
        result: {
          data: {
            postAssignmentGrades: {
              __typename: 'postAssignmentGrades',
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
          query: Api.POST_ASSIGNMENT_GRADES,
          variables: {assignmentId: ASSIGNMENT_ID, gradedOnly: true},
        },
        result: {
          data: {
            postAssignmentGrades: {
              __typename: 'postAssignmentGrades',
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
          query: Api.POST_ASSIGNMENT_GRADES,
          variables: {assignmentId: BAD_ASSIGNMENT_ID, gradedOnly: false},
        },
        result: {
          data: null,
          errors: [{message: 'a graphql error'}],
        },
      },
      {
        request: {
          query: Api.POST_ASSIGNMENT_GRADES_FOR_SECTIONS,
          variables: {assignmentId: ASSIGNMENT_ID, gradedOnly: false, sectionIds: SECTION_IDS},
        },
        result: {
          data: {
            postAssignmentGradesForSections: {
              __typename: 'postAssignmentGradesForSections',
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
          query: Api.POST_ASSIGNMENT_GRADES_FOR_SECTIONS,
          variables: {assignmentId: ASSIGNMENT_ID, gradedOnly: true, sectionIds: SECTION_IDS},
        },
        result: {
          data: {
            postAssignmentGradesForSections: {
              __typename: 'postAssignmentGradesForSections',
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
          query: Api.POST_ASSIGNMENT_GRADES_FOR_SECTIONS,
          variables: {assignmentId: BAD_ASSIGNMENT_ID, gradedOnly: false, sectionIds: SECTION_IDS},
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
  })

  describe('.postAssignmentGrades()', () => {
    test('accepts an optional gradedOnly argument', async () => {
      const progress = await Api.postAssignmentGrades(ASSIGNMENT_ID, {gradedOnly: true})
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      deepEqual(progress, expectedProgress)
    })

    test('returns the Progress', async () => {
      const progress = await Api.postAssignmentGrades(ASSIGNMENT_ID)
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      deepEqual(progress, expectedProgress)
    })

    test('consumers are required to handle when mutating rejects', async () => {
      try {
        await Api.postAssignmentGrades(BAD_ASSIGNMENT_ID)
      } catch (error) {
        strictEqual(error.message, 'a graphql error')
      }
    })
  })

  describe('.postAssignmentGradesForSections()', () => {
    test('accepts an optional gradedOnly argument', async () => {
      const progress = await Api.postAssignmentGradesForSections(ASSIGNMENT_ID, SECTION_IDS, {
        gradedOnly: true,
      })
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      deepEqual(progress, expectedProgress)
    })

    test('returns the Progress', async () => {
      const progress = await Api.postAssignmentGradesForSections(ASSIGNMENT_ID, SECTION_IDS)
      const expectedProgress = {id: PROGRESS_ID, workflowState: 'queued'}
      deepEqual(progress, expectedProgress)
    })

    test('consumers are required to handle when mutating rejects', async () => {
      try {
        await Api.postAssignmentGradesForSections(BAD_ASSIGNMENT_ID, SECTION_IDS)
      } catch (error) {
        strictEqual(error.message, 'a graphql error')
      }
    })
  })

  describe('.resolvePostAssignmentGradesStatus', () => {
    const server = setupServer()

    beforeAll(() => server.listen())
    afterEach(() => server.resetHandlers())
    afterAll(() => server.close())

    test('returns ids of submissions posted when job finishes', async () => {
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
      const results = await Api.resolvePostAssignmentGradesStatus({
        id: PROGRESS_ID,
        workflowState: 'queued',
      })
      deepEqual(results.submissionIds, ['201', '202', '203'])
    })

    test('consumers are required to handle when job fails', async () => {
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

      try {
        await Api.resolvePostAssignmentGradesStatus({id: PROGRESS_ID, workflowState: 'queued'})
      } catch (error) {
        strictEqual(error, 'job failed')
      }
    })
  })
})
