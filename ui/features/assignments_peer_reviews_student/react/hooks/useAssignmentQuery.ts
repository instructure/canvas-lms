/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useQuery} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'
import {PEER_REVIEW_ASSIGNMENT_QUERY} from '../queries'
import {Submission} from '../AssignmentsPeerReviewsStudentTypes'

export interface AssessmentRequest {
  _id: string
  available: boolean | null
  workflowState: string
  createdAt: string
  submission: Submission | null
}

export interface PeerReviews {
  count: number | null
}

export interface Assignment {
  _id: string
  name: string
  dueAt: string | null
  description: string | null
  courseId: string
  peerReviews: PeerReviews | null
  assessmentRequestsForCurrentUser: AssessmentRequest[] | null
}

interface AssignmentQueryData {
  assignment: Assignment
}

interface AssignmentQueryVariables {
  assignmentId: string
}

export function useAssignmentQuery(assignmentId: string) {
  return useQuery({
    queryKey: ['peerReviewAssignment', assignmentId],
    queryFn: async () => {
      const result = await executeQuery<AssignmentQueryData, AssignmentQueryVariables>(
        PEER_REVIEW_ASSIGNMENT_QUERY,
        {assignmentId},
      )
      return result
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}
