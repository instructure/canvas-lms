/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import AttemptSelect from './AttemptSelect'
import AssignmentDetails from './AssignmentDetails'
import PeerReviewsCounter from './PeerReviewsCounter'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import GradeDisplay from './GradeDisplay'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {Badge} from '@instructure/ui-badge'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {IconChatLine, IconQuestionLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import LatePolicyToolTipContent from './LatePolicyStatusDisplay/LatePolicyToolTipContent'
import {Popover} from '@instructure/ui-popover'
import {arrayOf, func} from 'prop-types'
import OriginalityReport from './OriginalityReport'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import SubmissionStatusPill from '@canvas/assignments/react/SubmissionStatusPill'
import SubmissionWorkflowTracker from './SubmissionWorkflowTracker'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import CommentsTray from './CommentsTray/index'
import {
  getOriginalityData,
  isOriginalityReportVisible,
} from '@canvas/grading/originalityReportHelper'

const I18n = useI18nScope('assignments_2_student_header')

class Header extends React.Component {
  static propTypes = {
    allSubmissions: arrayOf(Submission.shape),
    assignment: Assignment.shape,
    onChangeSubmission: func,
    submission: Submission.shape,
    reviewerSubmission: Submission.shape,
  }

  static defaultProps = {
    onChangeSubmission: () => {},
    reviewerSubmission: null,
  }

  isPeerReviewModeEnabled = () => {
    return this.props.assignment.env.peerReviewModeEnabled
  }

  state = {
    commentsTrayOpen:
      !!this.props.submission?.unreadCommentCount ||
      (!!this.isPeerReviewModeEnabled() &&
        this.props.assignment.env.peerReviewAvailable &&
        !this.props.assignment.rubric),
  }

  isSubmissionLate = () => {
    if (!this.props.submission || this.props.submission.gradingStatus !== 'graded') {
      return false
    }
    return (
      this.props.submission.latePolicyStatus === 'late' ||
      this.props.submission.submissionStatus === 'late'
    )
  }

  currentAssessmentIndex = () => {
    const userId = this.props.assignment.env.revieweeId
    const anonymousId = this.props.assignment.env.anonymousAssetId
    const value =
      this.props.reviewerSubmission?.assignedAssessments?.findIndex(assessment => {
        return (
          (userId && userId === assessment.anonymizedUser._id) ||
          (anonymousId && assessment.anonymousId === anonymousId)
        )
      }) || 0
    return value + 1
  }

  openCommentsTray = () => {
    this.setState({commentsTrayOpen: true})
  }

  closeCommentsTray = () => {
    this.setState({commentsTrayOpen: false})
  }

  renderLatestGrade = () => (
    <StudentViewContext.Consumer>
      {context => {
        const submission = context.lastSubmittedSubmission || {grade: null, gradingStatus: null}
        const {assignment} = this.props
        const gradeDisplay = (
          <GradeDisplay
            gradingStatus={submission.gradingStatus}
            gradingType={assignment.gradingType}
            receivedGrade={submission.grade}
            receivedScore={submission.score}
            pointsPossible={assignment.pointsPossible}
          />
        )

        if (
          !ENV.restrict_quantitative_data &&
          this.isSubmissionLate(submission) &&
          !submission.gradeHidden
        ) {
          return (
            <Tooltip
              as="div"
              renderTip={
                <LatePolicyToolTipContent
                  attempt={submission.attempt}
                  grade={submission.grade}
                  gradingType={assignment.gradingType}
                  originalGrade={submission.enteredGrade}
                  pointsDeducted={submission.deductedPoints}
                  pointsPossible={assignment.pointsPossible}
                />
              }
              on={['hover', 'focus']}
              placement="bottom"
            >
              {gradeDisplay}
            </Tooltip>
          )
        }

        return gradeDisplay
      }}
    </StudentViewContext.Consumer>
  )

  selectedSubmissionGrade = () => {
    const {assignment, submission} = this.props
    if (
      submission.gradingStatus === 'excused' ||
      (ENV.restrict_quantitative_data &&
        GradeFormatHelper.QUANTITATIVE_GRADING_TYPES.includes(assignment.gradingType) &&
        assignment.pointsPossible === 0 &&
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

    const textProps =
      submission.grade != null ? {weight: 'bold', transform: 'capitalize'} : {color: 'secondary'}

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
            <Text {...textProps}>{formattedGrade}</Text>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  renderViewFeedbackButton = (addCommentsDisabled, popoverMessage) => {
    return (
      <>
        <div>
          <StudentViewContext.Consumer>
            {context => {
              const button = (
                <Button
                  renderIcon={IconChatLine}
                  onClick={this.openCommentsTray}
                  disabled={addCommentsDisabled}
                >
                  {(this.props.submission && this.props.submission.feedbackForCurrentAttempt) ||
                  !context.allowChangesToSubmission
                    ? I18n.t('View Feedback')
                    : I18n.t('Add Comment')}
                </Button>
              )

              const unreadCount = this.props.submission?.unreadCommentCount
              if (this.isPeerReviewModeEnabled() || !unreadCount) return button

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
                <Link size="small" renderIcon={IconQuestionLine}>
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

  render() {
    const lockAssignment =
      this.props.assignment.env.modulePrereq || this.props.assignment.env.unlockDate

    const {peerReviewModeEnabled, peerReviewAvailable} = this.props.assignment.env
    const shouldDisplayPeerReviewEmptyState = peerReviewModeEnabled && !peerReviewAvailable

    /* In the case where the current attempt is backed by a submission draft after the first,
     students are not able to leave comments. Disabling the add comments button and adding
     an info button will help make this clear. */
    const addCommentsDisabled =
      shouldDisplayPeerReviewEmptyState ||
      (!peerReviewModeEnabled &&
        this.props.submission?.attempt > 1 &&
        this.props.submission.state === 'unsubmitted')

    const unsubmittedDraftMessage = I18n.t(
      'After the first attempt, you cannot leave comments until you submit the assignment.'
    )
    const unavailablePeerReviewMessage = I18n.t(
      'You cannot leave comments until reviewer and reviewee submits the assignment.'
    )
    const popoverMessage = shouldDisplayPeerReviewEmptyState
      ? unavailablePeerReviewMessage
      : unsubmittedDraftMessage

    let topRightComponent
    if (this.isPeerReviewModeEnabled()) {
      topRightComponent = (
        <Flex.Item margin="0 small 0 0">
          <PeerReviewsCounter
            current={this.currentAssessmentIndex()}
            total={this.props.reviewerSubmission?.assignedAssessments?.length || 0}
          />
        </Flex.Item>
      )
    } else {
      topRightComponent = <Flex.Item>{this.renderLatestGrade()}</Flex.Item>
    }

    return (
      <>
        <div
          data-testid="assignment-student-header"
          id="assignments-2-student-header"
          className="assignment-student-header"
        >
          <Heading level="h1">
            {/* We hide this because in the designs, what visually looks like should
              be the h1 appears after the group/module links, but we need the
              h1 to actually come before them for a11y */}
            <ScreenReaderContent> {this.props.assignment.name} </ScreenReaderContent>
          </Heading>

          <Flex as="div" margin="0" wrap="wrap" alignItems="start">
            <Flex.Item shouldShrink={true}>
              <AssignmentDetails assignment={this.props.assignment} />
            </Flex.Item>
            {this.props.submission && (
              <Flex.Item shouldGrow={true}>
                <Flex as="div" justifyItems="end" alignItems="center">
                  <Flex.Item margin="0 x-small 0 0">
                    <SubmissionStatusPill
                      submissionStatus={this.props.submission.submissionStatus}
                    />
                  </Flex.Item>
                  {topRightComponent}
                </Flex>

                <CommentsTray
                  submission={this.props.submission}
                  reviewerSubmission={this.props.reviewerSubmission}
                  assignment={this.props.assignment}
                  open={this.state.commentsTrayOpen}
                  closeTray={this.closeCommentsTray}
                  isPeerReviewEnabled={this.isPeerReviewModeEnabled()}
                />
              </Flex.Item>
            )}
          </Flex>
          <Flex alignItems="center" wrap="wrap">
            <Flex.Item shouldGrow={true}>
              {this.props.submission && !this.props.assignment.nonDigitalSubmission && (
                <Flex wrap="wrap">
                  {this.props.allSubmissions && !this.isPeerReviewModeEnabled() && (
                    <Flex.Item>
                      <AttemptSelect
                        allSubmissions={this.props.allSubmissions}
                        onChangeSubmission={this.props.onChangeSubmission}
                        submission={this.props.submission}
                      />
                    </Flex.Item>
                  )}

                  {this.props.assignment.env.currentUser &&
                    !lockAssignment &&
                    !this.isPeerReviewModeEnabled() && (
                      <Flex.Item>
                        <SubmissionWorkflowTracker submission={this.props.submission} />
                      </Flex.Item>
                    )}

                  {this.props.assignment.env.currentUser &&
                    !lockAssignment &&
                    (this.props.submission.submissionType === 'online_text_entry' ||
                      this.props.submission.attachments.length === 1) &&
                    this.props.submission.originalityData &&
                    this.props.assignment.env.originalityReportsForA2Enabled &&
                    isOriginalityReportVisible(
                      this.props.assignment.originalityReportVisibility,
                      this.props.assignment.dueAt,
                      this.props.submission.gradingStatus
                    ) &&
                    getOriginalityData(this.props.submission, 0) && (
                      <Flex.Item>
                        <OriginalityReport
                          originalityData={getOriginalityData(this.props.submission, 0)}
                        />
                      </Flex.Item>
                    )}
                </Flex>
              )}
            </Flex.Item>
            <Flex.Item shouldShrink={true}>
              <Flex as="div" wrap="wrap">
                {!this.isPeerReviewModeEnabled() &&
                  this.props.submission &&
                  (this.props.submission.state === 'graded' ||
                    this.props.submission.state === 'submitted') && (
                    <Flex.Item margin="0 small 0 0">{this.selectedSubmissionGrade()}</Flex.Item>
                  )}
                <Flex.Item margin="0 small 0 0">
                  {this.renderViewFeedbackButton(addCommentsDisabled, popoverMessage)}
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </div>
      </>
    )
  }
}

export default Header
