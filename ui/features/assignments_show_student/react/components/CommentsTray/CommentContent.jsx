/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {bool, arrayOf} from 'prop-types'
import CommentRow from './CommentRow'
import {useScope as useI18nScope} from '@canvas/i18n'
import {MARK_SUBMISSION_COMMENT_READ} from '@canvas/assignments/graphql/student/Mutations'
import noComments from '../../../images/NoComments.svg'
import noCommentsPeerReview from '../../../images/noCommentsPeerReview.svg'
import React, {useContext, useEffect} from 'react'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {
  SUBMISSION_COMMENT_QUERY,
  SUBMISSION_HISTORIES_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionComment} from '@canvas/assignments/graphql/student/SubmissionComment'
import SVGWithTextPlaceholder from '../../SVGWithTextPlaceholder'
import {useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('assignments_2')

export default function CommentContent(props) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [markCommentsRead, {data, called: mutationCalled, error: mutationError}] = useMutation(
    MARK_SUBMISSION_COMMENT_READ,
    {
      update(cache, result) {
        // ValidationError, different then the mutationError
        if (result.data?.markSubmissionCommentsRead?.errors) {
          return
        }

        // Set the read status for all of the submission comments we just
        // marked as read. I'm sad apollo isn't smart enough to do this without
        // us manually having to update the cache.
        const ids = result.data.markSubmissionCommentsRead.submissionComments.map(c => c._id)
        const updatedCommentIDs = new Set(ids)
        const commentQueryVariables = {
          query: SUBMISSION_COMMENT_QUERY,
          variables: {
            submissionId: props.submission.id,
            submissionAttempt: props.submission.attempt,
            peerReview: props.isPeerReviewEnabled,
          },
        }

        const {submissionComments} = JSON.parse(
          JSON.stringify(cache.readQuery(commentQueryVariables))
        )
        submissionComments.commentsConnection.nodes.forEach(comment => {
          if (updatedCommentIDs.has(comment._id)) {
            comment.read = true
          }
        })

        cache.writeQuery({
          ...commentQueryVariables,
          data: {submissionComments},
        })

        // Now update the unreadCommentCount. We have to handle the current
        // submission and submission histories separately as they exist in
        // different parts in the apollo cache. Try the current submission first
        const submissionQueryVariables = {
          id: props.submission.id,
          fragment: Submission.fragment,
          fragmentName: 'Submission',
          variables: {submissionID: props.submission.id},
        }
        const cachedCurrentSubmission = cache.readFragment(submissionQueryVariables)

        if (props.submission.attempt === cachedCurrentSubmission.attempt) {
          const submission = JSON.parse(JSON.stringify(cachedCurrentSubmission))
          const newUnreadCount = Math.max(0, submission.unreadCommentCount - updatedCommentIDs.size)
          submission.unreadCommentCount = newUnreadCount
          cache.writeFragment({...submissionQueryVariables, data: submission})
        } else {
          const cachedHistories = cache.readQuery({
            query: SUBMISSION_HISTORIES_QUERY,
            variables: {submissionID: props.submission.id},
          })

          const histories = JSON.parse(JSON.stringify(cachedHistories))
          histories.node.submissionHistoriesConnection.nodes.forEach(history => {
            if (history.attempt !== props.submission.attempt) {
              return
            }

            const newUnreadCount = Math.max(0, history.unreadCommentCount - updatedCommentIDs.size)
            history.unreadCommentCount = newUnreadCount
          })

          cache.writeQuery({
            query: SUBMISSION_HISTORIES_QUERY,
            variables: {submissionID: props.submission.id},
            data: histories,
          })
        }
      },
    }
  )

  // Mark unread comments as read when the tray is opened
  useEffect(() => {
    const unreadComments = props.comments.filter(c => !c.read)
    if (unreadComments.length > 0) {
      const commentIds = props.comments
        .filter(comment => comment.read === false)
        .map(comment => comment._id)
      const timer = setTimeout(() => {
        markCommentsRead({variables: {commentIds, submissionId: props.submission.id}})
      }, 1000)

      return () => clearTimeout(timer)
    }
  }, [markCommentsRead, props.comments, props.submission])

  useEffect(() => {
    if (mutationCalled && !mutationError && !data?.markSubmissionCommentsRead?.errors) {
      setOnSuccess(I18n.t('All submission comments have been marked as read'))
    } else if (mutationError || data?.markSubmissionCommentsRead?.errors) {
      setOnFailure(I18n.t('There was a problem marking submission comments as read'))
    }
  }, [data, mutationCalled, mutationError, setOnFailure, setOnSuccess])

  const defaultText = I18n.t(
    "This is where you can leave a comment and view your instructor's feedback."
  )
  const peerReviewText = I18n.t(
    'Add a comment to complete your peer review. You will only see comments written by you.'
  )
  const rubricPeerReviewText = I18n.t('You will only see comments written by you.')

  const peerReviewCompleteText = I18n.t('Your peer review is complete!')

  let placeholder
  if (!props.comments.length) {
    if (props.isPeerReviewEnabled) {
      if (props.assignment.rubric) {
        placeholder = (
          <SVGWithTextPlaceholder text={rubricPeerReviewText} url={noCommentsPeerReview} />
        )
      } else {
        placeholder = <SVGWithTextPlaceholder text={peerReviewText} url={noCommentsPeerReview} />
      }
    } else if (!props.submission.gradeHidden) {
      placeholder = <SVGWithTextPlaceholder text={defaultText} url={noComments} />
    }
  }
  const hasCompletedPeerReview = () => {
    const {reviewerSubmission, submission} = props
    if (!reviewerSubmission) return false

    const {assignedAssessments} = reviewerSubmission
    const matchingAssessment = assignedAssessments.find(x => x.assetId === submission._id)
    return matchingAssessment?.workflowState === 'completed'
  }
  return (
    <>
      {placeholder}
      {props.isPeerReviewEnabled && !props.assignment.rubric && hasCompletedPeerReview() && (
        <Alert
          variant="success"
          renderCloseButtonLabel="Close"
          margin="0 medium medium"
          transition="none"
        >
          {peerReviewCompleteText}
        </Alert>
      )}
      {props.comments
        .sort((a, b) => new Date(a.updatedAt) - new Date(b.updatedAt))
        .map(comment => (
          <View as="div" key={comment._id} padding="0 medium 0 x-small">
            <CommentRow comment={comment} />
            <hr style={{margin: '1rem 1.5rem'}} />
          </View>
        ))}
    </>
  )
}

CommentContent.propTypes = {
  comments: arrayOf(SubmissionComment.shape).isRequired,
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired,
  isPeerReviewEnabled: bool,
  reviewerSubmission: Submission.shape,
}

CommentContent.defaultProps = {
  isPeerReviewEnabled: false,
}
