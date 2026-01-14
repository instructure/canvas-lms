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

import React from 'react'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import CommentsTray, {TrayContent} from '@canvas/assignments/react/CommentsTray'
import {Submission, Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'
import StudentViewContext, {
  StudentViewContextDefaults,
} from '@canvas/assignments/react/StudentViewContext'

const apolloClient = createClient()

interface ReviewerSubmission {
  _id: string
  id: string
  attempt: number
  assignedAssessments: {
    assetId: string
    workflowState: string
    assetSubmissionType: string | null
  }[]
}

interface CommentsTrayContentWithApolloProps {
  submission: Submission
  assignment: Assignment
  isPeerReviewEnabled?: boolean
  reviewerSubmission?: ReviewerSubmission | null
  renderTray: boolean
  closeTray: () => void
  open: boolean
  onSuccessfulPeerReview: () => void
  usePeerReviewModal?: boolean
  isReadOnly: boolean
}

/**
 * Wrapper component that provides Apollo Client context to CommentsTray
 * while allowing the rest of the app to use Tanstack Query
 */
const CommentsTrayContentWithApollo: React.FC<CommentsTrayContentWithApolloProps> = props => {
  // Convert Tanstack Query submission data to GraphQL format
  // GraphQL expects a base64-encoded global ID in the format "Submission-123"
  const graphqlGlobalId = btoa(`Submission-${props.submission._id}`)

  const formatSubmissionDataForCommentsTray = {
    ...props.submission,
    id: graphqlGlobalId,
    _id: props.submission._id,
  }

  // Add ENV data that CommentTextArea expects
  const assignmentWithEnv = {
    ...props.assignment,
    env: {
      currentUser: ENV.current_user,
      courseId: props.assignment.courseId,
    },
  }

  const formattedProps = {
    ...props,
    submission: formatSubmissionDataForCommentsTray,
    assignment: assignmentWithEnv,
  }

  const studentViewContextValue = {
    ...StudentViewContextDefaults,
    allowPeerReviewComments: !props.isReadOnly,
  }

  return (
    <ApolloProvider client={apolloClient}>
      <StudentViewContext.Provider value={studentViewContextValue}>
        {props.renderTray ? (
          <CommentsTray {...formattedProps} />
        ) : (
          <TrayContent {...formattedProps} />
        )}
      </StudentViewContext.Provider>
    </ApolloProvider>
  )
}

export default CommentsTrayContentWithApollo
