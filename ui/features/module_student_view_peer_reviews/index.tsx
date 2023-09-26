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

import {createClient} from '@canvas/apollo'
import {
  AssignmentPeerReview,
  StudentViewPeerReviews,
} from '@canvas/student_view_peer_reviews/react/StudentViewPeerReviews'
import ready from '@instructure/ready'
import {Assignment} from 'api'
import $ from 'jquery'
import React, {ReactElement} from 'react'
import ReactDOM from 'react-dom'
import ASSIGNMENT_QUERY from './graphql/Queries'

type AssessmentRequest = {
  anonymous_id?: string
  available?: boolean
  createdAt: string
  user_id?: string
  user_name?: string
  workflow_state?: string
}

type AssignmentPeerReviewSubset = Pick<
  Assignment,
  'id' | 'course_id' | 'anonymous_peer_reviews' | 'name'
>

type ExpandedAssignmentPeerReview = AssignmentPeerReviewSubset & {
  assessment_requests: Array<AssessmentRequest> | []
}

type GraphQLAssesmentRequest = {
  _id: string
  anonymousId: string
  available: boolean
  createdAt: string
  workflowState: string
  user: {
    _id: string
    name: string
  }
  anonymizedUser: {
    _id: string
    name: string
  }
}

type GraphQLAssignment = {
  _id: string
  assessmentRequestsForCurrentUser: Array<GraphQLAssesmentRequest>
  name: string
  peerReviews: {
    anonymousReviews: boolean
  }
}

type GraphQLModuleItemData = {
  moduleItems: Array<{
    content: GraphQLAssignment
    _id: string
  }>
}

type GraphQLResponse = {
  data: {
    course: {
      modulesConnection: {
        nodes: Array<{
          moduleItems: Array<GraphQLModuleItemData>
        }>
      }
    }
  }
}

type StudentViewPeerReviewsAssignment = {
  [assignmentId: string]: {
    assignment: ExpandedAssignmentPeerReview
    container: ReactElement | undefined
  }
}

function getAssignments({courseId}: {courseId: String}) {
  return createClient()
    .query({
      query: ASSIGNMENT_QUERY,
      variables: {courseId},
    })
    .then((response: GraphQLResponse) => {
      const queryResponse = response && response.data && response.data.course

      if (queryResponse) {
        const moduleItems = queryResponse?.modulesConnection?.nodes

        if (moduleItems != null) {
          return moduleItems
        }
      }
    })
}

function formatAssesmentRequest(assessmentRequest: GraphQLAssesmentRequest): AssessmentRequest {
  const {
    anonymizedUser,
    anonymousId: anonymous_id,
    available,
    createdAt,
    user,
    workflowState,
  } = assessmentRequest
  const {_id: user_id, name: user_name} = user
  const {name: anonymized_user_name} = anonymizedUser

  const formattedAssessmentRequest: AssessmentRequest = {
    anonymous_id,
    available,
    createdAt,
    user_id,
    user_name: anonymized_user_name ?? user_name,
    workflow_state: workflowState,
  }

  return formattedAssessmentRequest
}

function formatAssignment(
  assignment: GraphQLAssignment,
  moduleId: string
): {
  assessmentRequests: GraphQLAssesmentRequest[] | []
  assignmentId: string
  studentViewPeerReviewsAssignment: StudentViewPeerReviewsAssignment
} | null {
  const {
    _id: assignmentId,
    assessmentRequestsForCurrentUser: assessmentRequests = [],
    name,
    peerReviews,
  } = assignment

  if (assessmentRequests.length === 0) return null
  if (ENV.course_id == null) return null

  const container = $(`#module_student_view_peer_reviews_${assignmentId}_${moduleId}`)[0]
  const studentViewPeerReviewsAssignment: StudentViewPeerReviewsAssignment = {}
  const {anonymousReviews} = peerReviews

  studentViewPeerReviewsAssignment[assignmentId] = {
    assignment: {
      anonymous_peer_reviews: anonymousReviews,
      assessment_requests: [],
      course_id: ENV.course_id,
      id: assignmentId,
      name,
    },
    // @ts-expect-error
    container,
  }
  return {studentViewPeerReviewsAssignment, assessmentRequests, assignmentId}
}

function compareByCreatedAt(a: AssessmentRequest, b: AssessmentRequest) {
  const dateA = new Date(a.createdAt)
  const dateB = new Date(b.createdAt)

  if (dateA < dateB) {
    return -1
  } else if (dateA > dateB) {
    return 1
  } else {
    return 0
  }
}

ready(async () => {
  if (!ENV.course_id || JSON.stringify(ENV.current_user) === '{}') return

  const graphqlModuleItemsData: GraphQLModuleItemData[] = await getAssignments({
    courseId: ENV.course_id.toString(),
  })

  if (!graphqlModuleItemsData || graphqlModuleItemsData.length === 0) return

  const studentViewPeerReviewsAssignments: StudentViewPeerReviewsAssignment[] = []

  graphqlModuleItemsData.forEach(graphqlModuleItem => {
    if (
      !graphqlModuleItem ||
      (graphqlModuleItem.moduleItems && graphqlModuleItem.moduleItems.length === 0)
    )
      return

    const graphqlModuleItems = graphqlModuleItem.moduleItems

    graphqlModuleItems.forEach(graphqlModuleItem => {
      const assignment = graphqlModuleItem.content
      const moduleId = graphqlModuleItem._id
      const formattedAssignment = formatAssignment(assignment, moduleId)

      if (formattedAssignment == null) return

      const {studentViewPeerReviewsAssignment, assessmentRequests, assignmentId} =
        formattedAssignment

      if (assessmentRequests.length === 0) return

      const formattedAssessmentRequests: AssessmentRequest[] = []

      assessmentRequests.forEach(assessmentRequest => {
        const formattedAssessmentRequest = formatAssesmentRequest(assessmentRequest)
        formattedAssessmentRequests.push(formattedAssessmentRequest)
      })

      studentViewPeerReviewsAssignment[assignmentId].assignment.assessment_requests =
        formattedAssessmentRequests.sort(compareByCreatedAt)

      studentViewPeerReviewsAssignments.push(studentViewPeerReviewsAssignment)
    })

    const formattedAssginments = Object.entries(studentViewPeerReviewsAssignments)

    formattedAssginments.forEach(([_key, data]) => {
      Object.entries(data).forEach(([_key, value]) => {
        ReactDOM.render(
          // @ts-expect-error
          <StudentViewPeerReviews assignment={value.assignment as AssignmentPeerReview} />,
          value.container
        )
      })
    })
  })
})
