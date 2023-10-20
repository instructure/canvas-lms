// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import CommentContent from './CommentContent'
import CommentTextArea from './CommentTextArea'
import ErrorBoundary from '@canvas/error-boundary'
// @ts-ignore
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import SVGWithTextPlaceholder from '../../SVGWithTextPlaceholder'
// @ts-ignore
import ClosedDiscussionSVG from '../../../images/ClosedDiscussions.svg'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import React, {useContext, useState} from 'react'
import StudentViewContext from '../Context'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {useQuery} from 'react-apollo'
import {bool, func} from 'prop-types'
import PeerReviewPromptModal from '../PeerReviewPromptModal'
import {
  getRedirectUrlToFirstPeerReview,
  assignedAssessmentsCount,
  availableAndUnavailableCounts,
  getPeerReviewHeaderText,
  getPeerReviewSubHeaderText,
  getPeerReviewButtonText,
} from '../../helpers/PeerReviewHelpers'

const I18n = useI18nScope('assignments_2')
const COMPLETED_WORKFLOW_STATE = 'completed'

export default function CommentsTrayBody(props) {
  const [isFetchingMoreComments, setIsFetchingMoreComments] = useState(false)
  const [peerReviewModalOpen, setPeerReviewModalOpen] = useState(false)

  const queryVariables = {
    submissionId: props.submission.id,
    submissionAttempt: props.submission.attempt,
    peerReview: props.isPeerReviewEnabled,
  }

  const {loading, error, data, fetchMore} = useQuery(SUBMISSION_COMMENT_QUERY, {
    variables: queryVariables,
  })

  const {reviewerSubmission} = props
  const {assignedAssessments = []} = reviewerSubmission ?? {}
  const {availableCount, unavailableCount} = availableAndUnavailableCounts(assignedAssessments)

  const loadMoreComments = async () => {
    setIsFetchingMoreComments(true)
    await fetchMore({
      variables: {
        // @ts-ignore
        cursor: data.submissionComments.commentsConnection.pageInfo.startCursor,
        ...queryVariables,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        const newNodes = fetchMoreResult.submissionComments.commentsConnection.nodes
        const newPageInfo = fetchMoreResult.submissionComments.commentsConnection.pageInfo
        const results = JSON.parse(JSON.stringify(previousResult))
        results.submissionComments.commentsConnection.pageInfo = newPageInfo

        if (newNodes.length) {
          results.submissionComments.commentsConnection.nodes.push(...newNodes)
        }
        return results
      },
    })
    setIsFetchingMoreComments(false)
  }

  const handlePeerReviewPromptModal = () => {
    const matchingAssessment = assignedAssessments.find(x => x.assetId === props.submission._id)
    if (!matchingAssessment) return

    const {workflowState: previousWorkflowState} = matchingAssessment
    if (previousWorkflowState !== COMPLETED_WORKFLOW_STATE) {
      matchingAssessment.workflowState = COMPLETED_WORKFLOW_STATE
    }
    const remainingReviewCounts = assignedAssessmentsCount(assignedAssessments)
    if (!remainingReviewCounts && previousWorkflowState === COMPLETED_WORKFLOW_STATE) return

    setPeerReviewModalOpen(true)
  }

  const {allowChangesToSubmission} = useContext(StudentViewContext)

  const gradeAsGroup =
    props.assignment.groupCategoryId && !props.assignment.gradeGroupStudentsIndividually

  if (loading) return <LoadingIndicator />
  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject="Assignments 2 Student submission comments query error"
        errorCategory="Assignments 2 Student Error Page"
      />
    )
  }

  const comments = data.submissionComments.commentsConnection.nodes
  const hiddenCommentsMessage = I18n.t(
    'You may not see all comments for this assignment until grades are posted.'
  )
  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory="Assignments 2 Student Comment Error Page"
        />
      }
    >
      <Flex as="div" direction="column" height="100%" data-testid="comments-container">
        <Flex.Item shouldGrow={true}>
          {!props.isPeerReviewEnabled && props.submission.gradeHidden && comments.length === 0 && (
            <SVGWithTextPlaceholder
              text={hiddenCommentsMessage}
              url={ClosedDiscussionSVG}
              addMargin={true}
            />
          )}

          {!props.isPeerReviewEnabled && props.submission.gradeHidden && comments.length > 0 && (
            <Alert variant="info" margin="small small x-large">
              {hiddenCommentsMessage}
            </Alert>
          )}

          <div className="load-more-comments-button-container">
            {isFetchingMoreComments && <LoadingIndicator />}
            {data.submissionComments.commentsConnection.pageInfo.hasPreviousPage &&
              !isFetchingMoreComments && (
                <Button color="primary" onClick={loadMoreComments}>
                  {I18n.t('Load Previous Comments')}
                </Button>
              )}
          </div>

          <CommentContent
            comments={comments}
            assignment={props.assignment}
            submission={props.submission}
            isPeerReviewEnabled={props.isPeerReviewEnabled}
            reviewerSubmission={props.reviewerSubmission}
          />
        </Flex.Item>

        {allowChangesToSubmission && (
          <Flex as="div" direction="column">
            {gradeAsGroup && (
              <Flex.Item padding="x-small medium">
                <Text as="div">{I18n.t('All comments are sent to the whole group.')}</Text>
              </Flex.Item>
            )}

            <Flex.Item padding="x-small medium">
              <CommentTextArea
                assignment={props.assignment}
                submission={props.submission}
                reviewerSubmission={props.reviewerSubmission}
                isPeerReviewEnabled={props.isPeerReviewEnabled}
                onSendCommentSuccess={() => {
                  if (props.isPeerReviewEnabled && !props.assignment.rubric) {
                    handlePeerReviewPromptModal()
                    props.onSuccessfulPeerReview?.(props.reviewerSubmission)
                  }
                }}
              />
            </Flex.Item>
          </Flex>
        )}

        <PeerReviewPromptModal
          headerText={getPeerReviewHeaderText(availableCount, unavailableCount)}
          headerMargin={
            availableCount === 0 && unavailableCount === 0 ? 'small 0 x-large' : 'small 0 0'
          }
          subHeaderText={getPeerReviewSubHeaderText(availableCount, unavailableCount)}
          peerReviewButtonText={getPeerReviewButtonText(availableCount, unavailableCount)}
          peerReviewButtonDisabled={availableCount === 0}
          open={peerReviewModalOpen}
          onClose={() => setPeerReviewModalOpen(false)}
          onRedirect={() => {
            const url = getRedirectUrlToFirstPeerReview(assignedAssessments)
            if (url) window.location.assign(url)
          }}
        />
      </Flex>
    </ErrorBoundary>
  )
}

CommentsTrayBody.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired,
  reviewerSubmission: Submission.shape,
  isPeerReviewEnabled: bool,
  onSuccessfulPeerReview: func,
}

CommentsTrayBody.defaultProps = {
  isPeerReviewEnabled: false,
}
