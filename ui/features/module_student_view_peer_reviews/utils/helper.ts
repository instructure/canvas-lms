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

import type {
  AssessmentRequest,
  GraphQLAssesmentRequest,
  GraphQLAssignment,
  GraphQLModuleItemsNode,
  GraphQLResponse,
  StudentViewPeerReviewsAssignment,
} from '../types'
import ASSIGNMENT_QUERY from '../graphql/Queries'
import $ from 'jquery'
import {createClient} from '@canvas/apollo'
import type {ReactElement} from 'react'

export function formatAssessmentRequest({
  anonymizedUser,
  anonymousId,
  available,
  createdAt,
  user,
  workflowState,
}: GraphQLAssesmentRequest): AssessmentRequest {
  const {id: user_id, name: user_name} = user

  return {
    anonymous_id: anonymousId,
    available,
    createdAt,
    user_id,
    user_name: anonymizedUser?.name ?? user_name,
    workflow_state: workflowState,
  }
}

export function formatAssignment(
  {
    _id: assignmentId,
    assessmentRequestsForCurrentUser: assessmentRequests = [],
    name,
    peerReviews,
  }: GraphQLAssignment,
  moduleId: string
): {
  assessmentRequests: GraphQLAssesmentRequest[] | []
  assignmentId: string
  studentViewPeerReviewsAssignment: StudentViewPeerReviewsAssignment
} | null {
  if (assessmentRequests.length === 0 || ENV.course_id == null) return null

  // @ts-expect-error
  const container: ReactElement | undefined = $(
    `#module_student_view_peer_reviews_${assignmentId}_${moduleId}`
  )[0]

  const {anonymousReviews} = peerReviews

  return {
    studentViewPeerReviewsAssignment: {
      [assignmentId]: {
        assignment: {
          anonymous_peer_reviews: anonymousReviews,
          assessment_requests: [],
          course_id: ENV.course_id,
          id: assignmentId,
          name,
        },
        container,
      },
    },
    assessmentRequests,
    assignmentId,
  }
}

export function compareByCreatedAt(a: AssessmentRequest, b: AssessmentRequest) {
  const dateA = new Date(a.createdAt)
  const dateB = new Date(b.createdAt)

  return dateA.getTime() - dateB.getTime()
}

export function formatGraphqlModuleNodes(
  graphqlModuleItemNodes: GraphQLModuleItemsNode[]
): [string, StudentViewPeerReviewsAssignment][] {
  const studentViewPeerReviewsAssignments: StudentViewPeerReviewsAssignment[] = []

  const filteredNodes = graphqlModuleItemNodes.filter(
    node => node && node.moduleItems && node.moduleItems.length > 0
  )

  filteredNodes.forEach(({id: moduleId, moduleItems}) => {
    moduleItems.forEach(({content: assignment}) => {
      const formattedAssignment = formatAssignment(assignment, moduleId)

      if (!formattedAssignment) return

      const {studentViewPeerReviewsAssignment, assessmentRequests, assignmentId} =
        formattedAssignment

      if (!assessmentRequests.length) return

      const formattedAssessmentRequests = assessmentRequests.map(formatAssessmentRequest)
      studentViewPeerReviewsAssignment[assignmentId].assignment.assessment_requests =
        formattedAssessmentRequests.sort(compareByCreatedAt)

      studentViewPeerReviewsAssignments.push(studentViewPeerReviewsAssignment)
    })
  })

  return Object.entries(studentViewPeerReviewsAssignments)
}

export async function getAssignments(courseId: string): Promise<Array<GraphQLModuleItemsNode>> {
  return createClient()
    .query({
      query: ASSIGNMENT_QUERY,
      variables: {courseId},
    })
    .then((response: GraphQLResponse) => {
      const queryResponse = response && response.data && response.data.course

      if (queryResponse) {
        const moduleItemNodes = queryResponse?.modulesConnection?.nodes

        if (moduleItemNodes != null) return moduleItemNodes
      }
    })
}
