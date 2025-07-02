/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../../msw/mswServer'
import fakeENV from '@canvas/test-utils/fakeENV'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'

const server = mswServer([])

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  fakeENV.setup()
})

afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
})

afterAll(() => {
  server.close()
})

describe('Assignment', () => {
  describe('duplication functionality', () => {
    describe('#canDuplicate', () => {
      it('returns true if record can be duplicated', () => {
        const assignment = new Assignment({
          name: 'foo',
          can_duplicate: true,
        })
        expect(assignment.canDuplicate()).toBe(true)
      })

      it('returns false if record cannot be duplicated', () => {
        const assignment = new Assignment({
          name: 'foo',
          can_duplicate: false,
        })
        expect(assignment.canDuplicate()).toBe(false)
      })
    })

    describe('#isDuplicating', () => {
      it('returns true if record is duplicating', () => {
        const assignment = new Assignment({
          name: 'foo',
          workflow_state: 'duplicating',
        })
        expect(assignment.isDuplicating()).toBe(true)
      })

      it('returns false if record is not duplicating', () => {
        const assignment = new Assignment({
          name: 'foo',
          workflow_state: 'published',
        })
        expect(assignment.isDuplicating()).toBe(false)
      })
    })

    describe('#failedToDuplicate', () => {
      it('returns true if record failed to duplicate', () => {
        const assignment = new Assignment({
          name: 'foo',
          workflow_state: 'failed_to_duplicate',
        })
        expect(assignment.failedToDuplicate()).toBe(true)
      })

      it('returns false if record did not fail to duplicate', () => {
        const assignment = new Assignment({
          name: 'foo',
          workflow_state: 'published',
        })
        expect(assignment.failedToDuplicate()).toBe(false)
      })
    })

    describe('#originalAssignmentID', () => {
      it('returns the original assignment id', () => {
        const originalAssignmentID = '42'
        const assignment = new Assignment({
          name: 'foo',
          original_assignment_id: originalAssignmentID,
        })
        expect(assignment.originalAssignmentID()).toBe(originalAssignmentID)
      })
    })

    describe('#originalCourseID', () => {
      it('returns the original course id', () => {
        const originalCourseID = '42'
        const assignment = new Assignment({
          name: 'foo',
          original_course_id: originalCourseID,
        })
        expect(assignment.originalCourseID()).toBe(originalCourseID)
      })
    })

    describe('#originalAssignmentName', () => {
      it('returns the original assignment name', () => {
        const originalAssignmentName = 'Original Assignment'
        const assignment = new Assignment({
          name: 'foo',
          original_assignment_name: originalAssignmentName,
        })
        expect(assignment.originalAssignmentName()).toBe(originalAssignmentName)
      })
    })

    describe('#duplicate_failed', () => {
      it('makes ajax call with correct url when duplicate_failed is called', async () => {
        const assignmentID = '200'
        const originalAssignmentID = '42'
        const courseID = '123'
        const originalCourseID = '234'
        const assignment = new Assignment({
          name: 'foo',
          id: assignmentID,
          original_assignment_id: originalAssignmentID,
          course_id: courseID,
          original_course_id: originalCourseID,
        })

        let capturedUrl = null
        server.use(
          http.post('*/api/v1/courses/*/assignments/*/duplicate', ({request}) => {
            capturedUrl = request.url
            return HttpResponse.json({success: true}, {status: 200})
          }),
        )

        const callback = jest.fn()
        assignment.duplicate_failed(callback)

        await new Promise(resolve => setTimeout(resolve, 10))

        expect(capturedUrl).toBe(
          `http://localhost/api/v1/courses/${originalCourseID}/assignments/${originalAssignmentID}/duplicate?target_assignment_id=${assignmentID}&target_course_id=${courseID}`,
        )
        expect(callback).toHaveBeenCalled()
        expect(callback.mock.calls[0][0]).toEqual({success: true})
      })
    })
  })

  describe('quiz and freeze functionality', () => {
    describe('#isQuizLTIAssignment', () => {
      it('returns true if record uses quizzes 2', () => {
        const assignment = new Assignment({
          name: 'foo',
          is_quiz_lti_assignment: true,
        })
        expect(assignment.isQuizLTIAssignment()).toBe(true)
      })

      it('returns false if record does not use quizzes 2', () => {
        const assignment = new Assignment({
          name: 'foo',
          is_quiz_lti_assignment: false,
        })
        expect(assignment.isQuizLTIAssignment()).toBe(false)
      })
    })

    describe('#canFreeze', () => {
      it('returns true if record is not frozen', () => {
        const assignment = new Assignment({
          name: 'foo',
          frozen_attributes: [],
        })
        expect(assignment.canFreeze()).toBe(true)
      })

      it('returns false if record is frozen', () => {
        const assignment = new Assignment({
          name: 'foo',
          frozen_attributes: [],
          frozen: true,
        })
        expect(assignment.canFreeze()).toBe(false)
      })

      it('returns false if record uses quizzes 2', () => {
        const assignment = new Assignment({
          name: 'foo',
          frozen_attributes: [],
        })
        jest.spyOn(assignment, 'isQuizLTIAssignment').mockReturnValue(true)
        expect(assignment.canFreeze()).toBe(false)
      })
    })

    describe('#submissionTypesFrozen', () => {
      it('returns false if submission types are not in frozenAttributes', () => {
        const assignment = new Assignment({frozen_attributes: ['foo']})
        expect(assignment.submissionTypesFrozen()).toBe(false)
      })

      it('returns true if submission_types are in frozenAttributes', () => {
        const assignment = new Assignment({frozen_attributes: ['submission_types']})
        expect(assignment.submissionTypesFrozen()).toBe(true)
      })
    })
  })
})
