/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {formatAssessmentRequest, compareByCreatedAt, formatAssignment} from '../../utils/helper'
import type {AssessmentRequest, GraphQLAssesmentRequest, GraphQLAssignment} from '../../types'

describe('Assessment Requests', () => {
  it('formats assessment request correctly', () => {
    const mockRequest: GraphQLAssesmentRequest = {
      id: '1',
      anonymizedUser: {id: '1', name: 'AnonymizedUser'},
      anonymousId: 'anonymousId123',
      available: true,
      createdAt: '2022-01-01T00:00:00Z',
      user: {id: 'userId123', name: 'UserName'},
      workflowState: 'active',
    }

    const result = formatAssessmentRequest(mockRequest)
    expect(result).toEqual({
      anonymous_id: 'anonymousId123',
      available: true,
      createdAt: '2022-01-01T00:00:00Z',
      user_id: 'userId123',
      user_name: 'AnonymizedUser',
      workflow_state: 'active',
    })
  })

  it('should sort by createdAt in ascending order', () => {
    const assessments: AssessmentRequest[] = [
      {createdAt: '2021-10-18T12:00:00Z'},
      {createdAt: '2021-10-18T12:05:00Z'},
      {createdAt: '2021-10-18T11:55:00Z'},
    ]

    const sorted = assessments.sort(compareByCreatedAt)

    expect(sorted[0].createdAt).toBe('2021-10-18T11:55:00Z')
    expect(sorted[1].createdAt).toBe('2021-10-18T12:00:00Z')
    expect(sorted[2].createdAt).toBe('2021-10-18T12:05:00Z')
  })

  it('should handle equal createdAt values', () => {
    const assessments: AssessmentRequest[] = [
      {createdAt: '2021-10-18T12:00:00Z'},
      {createdAt: '2021-10-18T12:00:00Z'},
      {createdAt: '2021-10-18T12:00:00Z'},
    ]

    const sorted = assessments.sort(compareByCreatedAt)

    expect(sorted[0].createdAt).toBe('2021-10-18T12:00:00Z')
    expect(sorted[1].createdAt).toBe('2021-10-18T12:00:00Z')
    expect(sorted[2].createdAt).toBe('2021-10-18T12:00:00Z')
  })

  describe('formatAssignment', () => {
    it('should return null when assessmentRequests is empty or course_id is null', () => {
      ENV.course_id = undefined

      const mockAssignment: GraphQLAssignment = {
        _id: '1',
        assessmentRequestsForCurrentUser: [],
        name: 'Test Assignment',
        peerReviews: {
          anonymousReviews: true,
        },
      }

      const result = formatAssignment(mockAssignment, 'module1')

      expect(result).toBe(null)
    })

    it('should return the formatted assignment object when assessmentRequests are present and course_id is not null', () => {
      ENV.course_id = 'course1'

      const mockAssignment: GraphQLAssignment = {
        _id: '1',
        assessmentRequestsForCurrentUser: [
          {
            id: 'req1',
            anonymousId: 'anon1',
            available: true,
            createdAt: '2023-01-01',
            workflowState: 'state1',
            user: {
              id: 'user1',
              name: 'User 1',
            },
            anonymizedUser: {
              id: 'anuser1',
              name: 'Anon User 1',
            },
          },
        ],
        name: 'Test Assignment',
        peerReviews: {
          anonymousReviews: true,
        },
      }

      const result = formatAssignment(mockAssignment, 'module1')

      expect(result).toEqual(
        expect.objectContaining({
          assignmentId: '1',
          assessmentRequests: expect.any(Array),
          studentViewPeerReviewsAssignment: expect.objectContaining({
            '1': expect.objectContaining({
              assignment: expect.objectContaining({
                id: '1',
                name: 'Test Assignment',
                course_id: 'course1',
              }),
            }),
          }),
        })
      )
    })
  })
})
