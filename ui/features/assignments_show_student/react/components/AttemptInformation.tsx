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

import React from 'react'
import AttemptSelect from './AttemptSelect'
import CommentsTray from './CommentsTray/index'
import OriginalityReport from './OriginalityReport'
import SubmissionWorkflowTracker from './SubmissionWorkflowTracker'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {Badge} from '@instructure/ui-badge'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import {IconChatLine, IconQuestionLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Popover} from '@instructure/ui-popover'
import type {Assignment, Submission} from '../../assignments_show_student'
import {
  getOriginalityData,
  isOriginalityReportVisible,
} from '@canvas/grading/originalityReportHelper'

const I18n = useI18nScope('assignments_2_student_content')

export type AttemptInformationProps = {
  assignment: Assignment
  submission: Submission
  reviewerSubmission: Submission
  onChangeSubmission: (reviewerSubmission: Submission) => void
  allSubmissions: Submission[]
  openCommentTray: () => void
  closeCommentTray: () => void
  commentTrayStatus: boolean
  onSuccessfulPeerReview: (reviewerSubmission: Submission) => void
}

export default ({
  assignment,
  submission,
  reviewerSubmission,
  onChangeSubmission,
  allSubmissions,
  openCommentTray,
  closeCommentTray,
  commentTrayStatus,
  onSuccessfulPeerReview,
}: AttemptInformationProps) => {
  const lockAssignment = assignment.env.modulePrereq || assignment.env.unlockDate
  const {peerReviewModeEnabled, peerReviewAvailable} = assignment.env
  const shouldDisplayPeerReviewEmptyState = peerReviewModeEnabled && !peerReviewAvailable

  const addCommentsDisabled =
    shouldDisplayPeerReviewEmptyState ||
    Boolean(
      submission &&
        !peerReviewModeEnabled &&
        submission.attempt != null &&
        submission.attempt > 1 &&
        submission.state === 'unsubmitted'
    )

  const unsubmittedDraftMessage = I18n.t(
    'After the first attempt, you cannot leave comments until you submit the assignment.'
  )
  const unavailablePeerReviewMessage = I18n.t(
    'You cannot leave comments until reviewer and reviewee submits the assignment.'
  )
  const popoverMessage = shouldDisplayPeerReviewEmptyState
    ? unavailablePeerReviewMessage
    : unsubmittedDraftMessage

  function selectedSubmissionGrade() {
    if (
      submission.gradingStatus === 'excused' ||
      (ENV.restrict_quantitative_data &&
        GradeFormatHelper.QUANTITATIVE_GRADING_TYPES.includes(assignment.gradingType) &&
        assignment.pointsPossible === 0 &&
        submission.score != null &&
        submission.score <= 0)
    ) {
      return null
    }

    const attemptGrade = submission.gradingStatus !== 'needs_grading' ? submission.grade : null
    const formattedGrade = GradeFormatHelper.formatGrade(attemptGrade, {
      defaultValue: I18n.t('N/A'),
      formatType: 'points_out_of_fraction',
      gradingType: assignment.gradingType,
      pointsPossible: assignment.pointsPossible,
      score: ENV.restrict_quantitative_data && submission.score != null ? submission.score : null,
      restrict_quantitative_data: ENV.restrict_quantitative_data,
      grading_scheme: ENV.grading_scheme,
    })

    return (
      <View className="selected-submission-grade">
        <Flex as="div" direction="column" alignItems="end">
          <Flex.Item>
            <Text size="small">
              {submission.attempt === 0
                ? I18n.t('Offline Score:')
                : I18n.t('Attempt %{attempt} Score:', {attempt: submission.attempt})}
            </Text>
          </Flex.Item>

          <Flex.Item>
            <Text
              transform={submission.grade != null ? 'capitalize' : 'none'}
              weight={submission.grade != null ? 'bold' : undefined}
              color={submission.grade != null ? undefined : 'secondary'}
            >
              {formattedGrade}
            </Text>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  function renderViewFeedbackButton() {
    return (
      <>
        <div>
          <StudentViewContext.Consumer>
            {context => {
              const button = (
                <Button
                  renderIcon={IconChatLine}
                  onClick={openCommentTray}
                  disabled={addCommentsDisabled}
                >
                  {(submission && submission.feedbackForCurrentAttempt) ||
                  !context.allowChangesToSubmission
                    ? I18n.t('View Feedback')
                    : I18n.t('Add Comment')}
                </Button>
              )

              const unreadCount = submission?.unreadCommentCount
              if (assignment.env.peerReviewModeEnabled || !unreadCount) return button

              return (
                <div data-testid="unread_comments_badge">
                  <Badge pulse={true} margin="x-small" count={unreadCount} countUntil={100}>
                    {button}
                  </Badge>
                </div>
              )
            }}
          </StudentViewContext.Consumer>
          {addCommentsDisabled && (
            <Popover
              renderTrigger={
                <Link renderIcon={IconQuestionLine}>
                  <ScreenReaderContent>{popoverMessage}</ScreenReaderContent>
                </Link>
              }
            >
              <View display="block" padding="small" maxWidth="15rem">
                {popoverMessage}
              </View>
            </Popover>
          )}
        </div>
      </>
    )
  }

  function renderAnonymousLabel() {
    return (
      <Flex
        as="div"
        direction="row"
        alignItems="end"
        data-testid="assignment-student-anonymus-label"
      >
        <Flex.Item padding="0 xxx-small 0 0">
          <Text size="small">{I18n.t('Anonymous Grading')}:</Text>
        </Flex.Item>
        <Flex.Item>
          <Text size="small" weight="bold">
            {submission?.gradedAnonymously ? I18n.t('yes') : I18n.t('no')}
          </Text>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <>
      {submission && (
        <CommentsTray
          submission={submission}
          reviewerSubmission={reviewerSubmission}
          assignment={assignment}
          open={commentTrayStatus}
          closeTray={closeCommentTray}
          isPeerReviewEnabled={peerReviewModeEnabled}
          onSuccessfulPeerReview={onSuccessfulPeerReview}
        />
      )}
      <Flex alignItems="center" wrap="wrap">
        <Flex.Item shouldGrow={true}>
          {submission && !assignment.nonDigitalSubmission && (
            <Flex wrap="wrap">
              {allSubmissions && !peerReviewModeEnabled && (
                <Flex.Item>
                  <AttemptSelect
                    allSubmissions={allSubmissions}
                    onChangeSubmission={onChangeSubmission}
                    submission={submission}
                  />
                </Flex.Item>
              )}

              {assignment.env.currentUser && !lockAssignment && !peerReviewModeEnabled && (
                <Flex.Item>
                  <SubmissionWorkflowTracker submission={submission} />
                </Flex.Item>
              )}

              {assignment.env.currentUser &&
                !lockAssignment &&
                (submission.submissionType === 'online_text_entry' ||
                  submission.attachments.length === 1) &&
                submission.originalityData &&
                assignment.env.originalityReportsForA2Enabled &&
                isOriginalityReportVisible(
                  assignment.originalityReportVisibility,
                  assignment.dueAt,
                  submission.gradingStatus
                ) &&
                getOriginalityData(submission, 0) && (
                  <Flex.Item>
                    <OriginalityReport originalityData={getOriginalityData(submission, 0)} />
                  </Flex.Item>
                )}
            </Flex>
          )}
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <Flex as="div" wrap="wrap">
            {!peerReviewModeEnabled &&
              submission &&
              (submission.state === 'graded' || submission.state === 'submitted') && (
                <Flex.Item margin="0 small 0 0">{selectedSubmissionGrade()}</Flex.Item>
              )}
            <Flex.Item>{renderViewFeedbackButton()}</Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      {submission?.grade && !submission?.hideGradeFromStudent && (
        <Flex justifyItems="end" direction="row">
          <Flex.Item shouldShrink={true}>
            <Flex as="div" wrap="wrap">
              <Flex.Item margin="0 small 0 0">{renderAnonymousLabel()}</Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      )}
    </>
  )
}
