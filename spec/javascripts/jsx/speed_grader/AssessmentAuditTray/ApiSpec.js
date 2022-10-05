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

import Api from 'ui/features/speed_grader/react/AssessmentAuditTray/Api'
import FakeServer, {
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'

QUnit.module('AssessmentAuditTray Api', suiteHooks => {
  let api
  let server

  suiteHooks.beforeEach(() => {
    server = new FakeServer()

    api = new Api()
  })

  suiteHooks.afterEach(() => {
    server.teardown()
  })

  QUnit.module('#loadAssessmentAuditTrail()', hooks => {
    const url = '/courses/1201/assignments/2301/submissions/2501/audit_events'

    let auditEvents
    let users
    let tools
    let quizzes

    hooks.beforeEach(() => {
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
      strictEqual(requests.length, 1)
    })

    test('sends a GET request', async () => {
      server
        .for(url)
        .respond({status: 200, body: {audit_events: auditEvents, users, tools, quizzes}})
      await loadAssessmentAuditTrail()
      const {method} = server.receivedRequests.find(request => pathFromRequest(request) === url)
      equal(method, 'GET')
    })

    QUnit.module('when the request succeeds', contextHooks => {
      let event
      let user
      let tool
      let quiz

      contextHooks.beforeEach(() => {
        server
          .for(url)
          .respond({status: 200, body: {audit_events: auditEvents, users, tools, quizzes}})

        return loadAssessmentAuditTrail().then(returnData => {
          event = returnData.auditEvents[0]
          user = returnData.users[0]
          tool = returnData.externalTools[0]
          quiz = returnData.quizzes[0]
        })
      })

      QUnit.module('returned event data', () => {
        test('normalizes the assignment id', () => {
          strictEqual(event.assignmentId, '2301')
        })

        test('normalizes the canvadoc id', () => {
          strictEqual(event.canvadocId, null)
        })

        test('normalizes the creation date', () => {
          deepEqual(event.createdAt, new Date('2018-08-28T16:46:44Z'))
        })

        test('normalizes the event type', () => {
          equal(event.eventType, 'grades_posted')
        })

        test('includes the payload', () => {
          deepEqual(event.payload, {grades_published_at: [null, '2018-08-28T16:46:43Z']})
        })

        test('normalizes the submission id', () => {
          strictEqual(event.submissionId, '2501')
        })

        test('normalizes the user id', () => {
          strictEqual(event.userId, '1101')
        })

        test('normalizes the external tool id', () => {
          strictEqual(event.externalToolId, null)
        })

        test('normalizes the quiz id', () => {
          strictEqual(event.quizId, null)
        })
      })

      QUnit.module('returned user data', () => {
        test('includes the user id', () => {
          strictEqual(user.id, '1101')
        })

        test('includes the user name', () => {
          strictEqual(user.name, 'The Greatest Grader')
        })

        test('includes the user role', () => {
          strictEqual(user.role, 'grader')
        })
      })

      QUnit.module('returned tool data', () => {
        test('includes the tool id', () => {
          strictEqual(tool.id, '25')
        })

        test('includes the tool name', () => {
          strictEqual(tool.name, 'Unicorn Tool')
        })

        test('includes the tool role', () => {
          strictEqual(tool.role, 'grader')
        })
      })

      QUnit.module('returned quiz data', () => {
        test('includes the quiz id', () => {
          strictEqual(quiz.id, '1101')
        })

        test('includes the quiz name', () => {
          strictEqual(quiz.name, 'Accessibility')
        })

        test('includes the quiz role', () => {
          strictEqual(quiz.role, 'grader')
        })
      })
    })

    QUnit.module('when the request fails', () => {
      test('does not catch the failure', async () => {
        server.for(url).respond({status: 500, body: {error: 'server error'}})
        try {
          await loadAssessmentAuditTrail()
        } catch (error) {
          ok(error.message.includes('500'))
        }
      })
    })
  })
})
