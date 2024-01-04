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
import AssignmentDetails from './AssignmentDetails'
import PeerReviewsCounter from './PeerReviewsCounter'
import {Flex} from '@instructure/ui-flex'
import GradeDisplay from './GradeDisplay'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import LatePolicyToolTipContent from './LatePolicyStatusDisplay/LatePolicyToolTipContent'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import SubmissionStatusPill from '@canvas/assignments/react/SubmissionStatusPill'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Tooltip} from '@instructure/ui-tooltip'
import PeerReviewNavigationLink from './PeerReviewNavigationLink'

const I18n = useI18nScope('assignments_2_student_header')

class Header extends React.Component {
  static propTypes = {
    assignment: Assignment.shape,
    submission: Submission.shape,
    reviewerSubmission: Submission.shape,
    peerReviewLinkData: Submission.shape,
  }

  static defaultProps = {
    reviewerSubmission: null,
  }

  isPeerReviewModeEnabled = () => {
    return this.props.assignment.env.peerReviewModeEnabled
  }

  state = {}

  isSubmissionLate = () => {
    if (!this.props.submission || this.props.submission.gradingStatus !== 'graded') {
      return false
    }
    return (
      this.props.submission.latePolicyStatus === 'late' ||
      this.props.submission.submissionStatus === 'late'
    )
  }

  currentAssessmentIndex = assignedAssessments => {
    const userId = this.props.assignment.env.revieweeId
    const anonymousId = this.props.assignment.env.anonymousAssetId
    const value =
      assignedAssessments?.findIndex(assessment => {
        return (
          (userId && userId === assessment.anonymizedUser._id) ||
          (anonymousId && assessment.anonymousId === anonymousId)
        )
      }) || 0
    return value + 1
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

  render() {
    let topRightComponent
    if (this.isPeerReviewModeEnabled()) {
      topRightComponent = (
        <Flex wrap="wrap">
          {this.props.peerReviewLinkData ? (
            <Flex.Item>
              <PeerReviewNavigationLink
                assignedAssessments={this.props.peerReviewLinkData?.assignedAssessments}
                currentAssessmentIndex={this.currentAssessmentIndex(
                  this.props.peerReviewLinkData?.assignedAssessments
                )}
              />
            </Flex.Item>
          ) : (
            <>
              {/* EVAL-3711 Remove ICE Feature Flag */}
              {!window.ENV.FEATURES.instui_nav && (
                <Flex.Item margin="0 small 0 0">
                  <PeerReviewsCounter
                    current={this.currentAssessmentIndex(
                      this.props.reviewerSubmission?.assignedAssessments
                    )}
                    total={this.props.reviewerSubmission?.assignedAssessments?.length || 0}
                  />
                </Flex.Item>
              )}
              <Flex.Item>
                <PeerReviewNavigationLink
                  assignedAssessments={this.props.reviewerSubmission?.assignedAssessments}
                  currentAssessmentIndex={this.currentAssessmentIndex(
                    this.props.reviewerSubmission?.assignedAssessments
                  )}
                />
              </Flex.Item>
            </>
          )}
        </Flex>
      )
    } else {
      topRightComponent = (
        <Flex wrap="wrap" alignItems="center">
          <Flex.Item padding="0 small 0 0">{this.renderLatestGrade()}</Flex.Item>
          {this.props.submission?.assignedAssessments?.length > 0 && (
            <Flex.Item>
              <PeerReviewNavigationLink
                assignedAssessments={this.props.submission.assignedAssessments}
                currentAssessmentIndex={0}
              />
            </Flex.Item>
          )}
        </Flex>
      )
    }
    return (
      <div data-testid="assignment-student-header" id="assignments-2-student-header">
        <Heading level="h1">
          {/* We hide this because in the designs, what visually looks like should
              be the h1 appears after the group/module links, but we need the
              h1 to actually come before them for a11y */}
          <ScreenReaderContent> {this.props.assignment.name} </ScreenReaderContent>
        </Heading>

        <Flex
          margin="0"
          alignItems="start"
          padding="0 0 large 0"
          id="assignment-student-header-content"
        >
          <Flex.Item shouldShrink={true} shouldGrow={true}>
            <AssignmentDetails
              assignment={this.props.assignment}
              submission={this.props.submission}
            />
          </Flex.Item>
          {this.props.peerReviewLinkData && <Flex.Item>{topRightComponent}</Flex.Item>}
          {this.props.submission && (
            <Flex.Item>
              <Flex as="div" alignItems="center">
                {/* EVAL-3711 Remove ICE Feature Flag */}
                {!window.ENV.FEATURES.instui_nav && (
                  <Flex.Item margin="0 x-small 0 0">
                    <SubmissionStatusPill
                      submissionStatus={this.props.submission.submissionStatus}
                      customGradeStatus={this.props.submission.customGradeStatus}
                    />
                  </Flex.Item>
                )}
                <Flex.Item>{topRightComponent}</Flex.Item>
              </Flex>
            </Flex.Item>
          )}
        </Flex>
      </div>
    )
  }
}

export default Header
