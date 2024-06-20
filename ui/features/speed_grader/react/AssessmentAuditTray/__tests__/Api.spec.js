/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Api from '../Api'
import FakeServer, {
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'

describe('AssessmentAuditTray Api', () => {
  let api
  let server

  beforeEach(() => {
    server = new FakeServer()
    api = new Api()
  })

  afterEach(() => {
    server.teardown()
  })

  describe('#loadAssessmentAuditTrail()', () => {
    const url = '/courses/1201/assignments/2301/submissions/2501/audit_events'

    let auditEvents
    let users
    let tools
    let quizzes

    beforeEach(() => {
      auditEvents = [
        {
          assignment_id: '2301',
          canvadoc_id: null,
          created_at: '2018-08-28T16:46:44Z',
          event_type: 'grades_posted',
          context_external_tool_id: null,
          id: '4901',
          payload: {
            grades_published_at: [null, '2018-08-28T16:46:43Z'],
          },
          quiz_id: null,
          submission_id: '2501',
          user_id: '1101',
        },
      ]

      users = [{id: '1101', name: 'The Greatest Grader', role: 'grader'}]
      tools = [{id: '25', name: 'Unicorn Tool', role: 'grader'}]
      quizzes = [{id: '1101', name: 'Accessibility', role: 'grader'}]
    })

    function loadAssessmentAuditTrail() {
      return api.loadAssessmentAuditTrail('1201', '2301', '2501')
    }

    test('sends a request to the "assessment audit events" url', async () => {
      server
        .for(url)
        .respond({status: 200, body: {audit_events: auditEvents, users, tools, quizzes}})
      await loadAssessmentAuditTrail()
      const requests = server.receivedRequests.filter(request => request.url === url)
      expect(requests.length).toBe(1)
    })

    test('sends a GET request', async () => {
      server
        .for(url)
        .respond({status: 200, body: {audit_events: auditEvents, users, tools, quizzes}})
      await loadAssessmentAuditTrail()
      const {method} = server.receivedRequests.find(request => pathFromRequest(request) === url)
      expect(method).toBe('GET')
    })

    describe('when the request succeeds', () => {
      let event
      let user
      let tool
      let quiz

      beforeEach(async () => {
        server
          .for(url)
          .respond({status: 200, body: {audit_events: auditEvents, users, tools, quizzes}})

        const returnData = await loadAssessmentAuditTrail()
        event = returnData.auditEvents[0]
        user = returnData.users[0]
        tool = returnData.externalTools[0]
        quiz = returnData.quizzes[0]
      })

      describe('returned event data', () => {
        test('normalizes the assignment id', () => {
          expect(event.assignmentId).toBe('2301')
        })

        test('normalizes the canvadoc id', () => {
          expect(event.canvadocId).toBe(null)
        })

        test('normalizes the creation date', () => {
          expect(event.createdAt).toEqual(new Date('2018-08-28T16:46:44Z'))
        })

        test('normalizes the event type', () => {
          expect(event.eventType).toBe('grades_posted')
        })

        test('includes the payload', () => {
          expect(event.payload).toEqual({grades_published_at: [null, '2018-08-28T16:46:43Z']})
        })

        test('normalizes the submission id', () => {
          expect(event.submissionId).toBe('2501')
        })

        test('normalizes the user id', () => {
          expect(event.userId).toBe('1101')
        })

        test('normalizes the external tool id', () => {
          expect(event.externalToolId).toBe(null)
        })

        test('normalizes the quiz id', () => {
          expect(event.quizId).toBe(null)
        })
      })

      describe('returned user data', () => {
        test('includes the user id', () => {
          expect(user.id).toBe('1101')
        })

        test('includes the user name', () => {
          expect(user.name).toBe('The Greatest Grader')
        })

        test('includes the user role', () => {
          expect(user.role).toBe('grader')
        })
      })

      describe('returned tool data', () => {
        test('includes the tool id', () => {
          expect(tool.id).toBe('25')
        })

        test('includes the tool name', () => {
          expect(tool.name).toBe('Unicorn Tool')
        })

        test('includes the tool role', () => {
          expect(tool.role).toBe('grader')
        })
      })

      describe('returned quiz data', () => {
        test('includes the quiz id', () => {
          expect(quiz.id).toBe('1101')
        })

        test('includes the quiz name', () => {
          expect(quiz.name).toBe('Accessibility')
        })

        test('includes the quiz role', () => {
          expect(quiz.role).toBe('grader')
        })
      })
    })

    describe('when the request fails', () => {
      test('does not catch the failure', async () => {
        server.for(url).respond({status: 500, body: {error: 'server error'}})
        try {
          await loadAssessmentAuditTrail()
        } catch (error) {
          expect(error.message).toContain('500')
        }
      })
    })
  })
})
