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

import React, {useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery, gql} from '@apollo/client'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import AlertManager from '@canvas/alerts/react/AlertManager'
import StudentViewContext, {
  StudentViewContextDefaults,
} from '@canvas/assignments/react/StudentViewContext'
import CommentRow from '@canvas/assignments/react/CommentsTray/CommentRow'
import CommentTextArea from '@canvas/assignments/react/CommentsTray/CommentTextArea'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('LearningMasteryGradebook')

const LoadingSpinner: React.FC = () => (
  <View as="div" padding="medium" textAlign="center">
    <Spinner size="small" renderTitle={I18n.t('Loading comments')} />
  </View>
)

interface CommentsSectionProps {
  courseId: string
  assignmentId: string
  studentId: string
}

// GraphQL query to get submission ID
const GET_SUBMISSION = gql`
  query GetSubmissionForComments($assignmentId: ID!, $userId: ID!) {
    assignment(id: $assignmentId) {
      _id
      id
      name
      pointsPossible
      expectsSubmission
      nonDigitalSubmission
      gradingType
      submissionTypes
      groupCategoryId
      gradeGroupStudentsIndividually
      submissionsConnection(filter: {userId: $userId}) {
        nodes {
          _id
          id
          attempt
          state
          gradingStatus
        }
      }
    }
  }
`

const CommentsSectionContent: React.FC<CommentsSectionProps> = ({
  courseId,
  assignmentId,
  studentId,
}) => {
  const {loading, error, data} = useQuery(GET_SUBMISSION, {
    variables: {
      assignmentId,
      userId: studentId,
    },
  })

  const {
    loading: commentsLoading,
    error: commentsError,
    data: commentsData,
  } = useQuery(SUBMISSION_COMMENT_QUERY, {
    variables: {
      submissionId: data?.assignment?.submissionsConnection?.nodes?.[0]?.id,
      submissionAttempt: data?.assignment?.submissionsConnection?.nodes?.[0]?.attempt || 1,
      peerReview: false,
    },
    skip: !data?.assignment?.submissionsConnection?.nodes?.[0]?.id,
  })

  useEffect(() => {
    if (error) {
      showFlashAlert({
        message: I18n.t('Failed to load submission comments'),
        type: 'error',
      })
    }
  }, [error])

  if (loading) {
    return <LoadingSpinner />
  }

  if (error || !data?.assignment) {
    return null
  }

  const assignment = data.assignment
  const submission = assignment.submissionsConnection?.nodes?.[0]

  if (!submission) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Text>{I18n.t('No submission found for this student and assignment.')}</Text>
      </View>
    )
  }

  // Create assignment object with required shape for comment components
  // Note: 'env' is not part of the GraphQL schema, but is required by the comment components
  const assignmentForComments = {
    ...assignment,
    env: {
      currentUser: {
        id: ENV.current_user_id,
        display_name: ENV.current_user?.display_name || 'Current User',
        avatar_image_url: ENV.current_user?.avatar_image_url || '',
      },
      courseId,
    },
  }

  const comments = commentsData?.submissionComments?.commentsConnection?.nodes || []

  return (
    <StudentViewContext.Provider
      value={{...StudentViewContextDefaults, allowPeerReviewComments: true}}
    >
      <AlertManager breakpoints={{}}>
        <View as="div" className="learning-mastery-comments">
          {commentsLoading && <LoadingSpinner />}
          {!commentsLoading && (
            <>
              {comments.length > 0 && (
                <View as="div" margin="0 0 small 0">
                  <Text weight="bold">{I18n.t('Comments')}</Text>
                  <View as="div" margin="small 0">
                    {[...comments]
                      .sort(
                        (a, b) => new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime(),
                      )
                      .map(comment => (
                        <View as="div" key={comment._id} margin="0 0 small 0">
                          <CommentRow comment={comment} />
                          <hr style={{margin: '0.75rem 0'}} />
                        </View>
                      ))}
                  </View>
                </View>
              )}
              <CommentTextArea
                assignment={assignmentForComments}
                submission={submission}
                isPeerReviewEnabled={false}
              />
            </>
          )}
        </View>
      </AlertManager>
    </StudentViewContext.Provider>
  )
}

export const CommentsSection: React.FC<CommentsSectionProps> = props => {
  return (
    <ApolloProvider client={createClient()}>
      <CommentsSectionContent {...props} />
    </ApolloProvider>
  )
}
