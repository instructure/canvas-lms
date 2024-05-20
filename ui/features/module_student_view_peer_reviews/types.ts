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

import type {Assignment} from 'api'
import type {ReactElement} from 'react'

export type GraphQLAssesmentRequest = {
  id: string
  anonymousId: string
  available: boolean
  createdAt: string
  workflowState: string
  user: {
    id: string
    name: string
  }
  anonymizedUser: {
    id?: string
    name?: string
  }
}

export type GraphQLAssignment = {
  _id: string
  assessmentRequestsForCurrentUser: Array<GraphQLAssesmentRequest>
  name: string
  peerReviews: {
    anonymousReviews: boolean
  }
}

export type GraphQLModuleItemsNode = {
  id: string
  moduleItems: Array<{content: GraphQLAssignment}>
}

export type GraphQLModuleItemData = {
  nodes: Array<GraphQLModuleItemsNode>
}

export type GraphQLResponse = {
  data: {
    course: {
      modulesConnection: GraphQLModuleItemData
    }
  }
}

export type AssessmentRequest = {
  anonymous_id?: string
  available?: boolean
  createdAt: string
  user_id?: string
  user_name?: string
  workflow_state?: string
}

export type AssignmentPeerReviewSubset = Pick<
  Assignment,
  'id' | 'course_id' | 'anonymous_peer_reviews' | 'name'
>

export type ExpandedAssignmentPeerReview = AssignmentPeerReviewSubset & {
  assessment_requests: Array<AssessmentRequest> | []
}

export type StudentViewPeerReviewsAssignment = {
  [assignmentId: string]: {
    assignment: ExpandedAssignmentPeerReview
    container: ReactElement | undefined
  }
}
