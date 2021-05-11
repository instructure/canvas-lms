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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import GradeDisplay from './GradeDisplay'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {Badge} from '@instructure/ui-badge'
import {Heading} from '@instructure/ui-heading'
import {IconChatLine} from '@instructure/ui-icons'
import I18n from 'i18n!assignments_2_student_header'
import LatePolicyStatusDisplay from './LatePolicyStatusDisplay/index'
import {arrayOf, func} from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import SubmissionStatusPill from '@canvas/assignments/react/SubmissionStatusPill'
import SubmissionWorkflowTracker from './SubmissionWorkflowTracker'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CommentsTray from './CommentsTray/index'

class Header extends React.Component {
  static propTypes = {
    allSubmissions: arrayOf(Submission.shape),
    assignment: Assignment.shape,
    onChangeSubmission: func,
    submission: Submission.shape
  }

  static defaultProps = {
    onChangeSubmission: () => {}
  }

  state = {
    commentsTrayOpen: false
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
        return (
          <GradeDisplay
            gradingStatus={submission.gradingStatus}
            gradingType={this.props.assignment.gradingType}
            receivedGrade={submission.grade}
            pointsPossible={this.props.assignment.pointsPossible}
          />
        )
      }}
    </StudentViewContext.Consumer>
  )

  selectedSubmissionGrade = () => {
    const {assignment, submission} = this.props
    if (submission.gradingStatus === 'excused') {
      return null
    }

    const formattedGrade = GradeFormatHelper.formatGrade(submission.grade, {
      defaultValue: I18n.t('N/A'),
      formatType: 'points_out_of_fraction',
      gradingType: assignment.gradingType,
      pointsPossible: assignment.pointsPossible
    })

    const textProps =
      submission.grade != null ? {weight: 'bold', transform: 'capitalize'} : {color: 'secondary'}

    return (
      <View className="selected-submission-grade">
        <Flex as="div" direction="column" alignItems="end">
          <Flex.Item>
            <Text size="small">
              {I18n.t('Attempt %{attempt} Score:', {attempt: submission.attempt})}
            </Text>
          </Flex.Item>

          <Flex.Item>
            <Text {...textProps}>{formattedGrade}</Text>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  renderViewFeedbackButton = () => {
    const buttonMargin = this.props.submission.unreadCommentCount ? {} : {margin: 'small xxx-small'}
    const button = (
      <Button renderIcon={IconChatLine} onClick={this.openCommentsTray} {...buttonMargin}>
        {I18n.t('View Feedback')}
      </Button>
    )

    if (!this.props.submission.unreadCommentCount) {
      return button
    }

    return (
      <Badge margin="x-small" count={this.props.submission.unreadCommentCount} countUntil={100}>
        {button}
      </Badge>
    )
  }

  render() {
    const lockAssignment =
      this.props.assignment.env.modulePrereq || this.props.assignment.env.unlockDate

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

          <Flex margin="0" wrap="wrap" wrapItems>
            <Flex.Item shrink>
              <AssignmentDetails assignment={this.props.assignment} />
            </Flex.Item>
            <Flex.Item grow align="start">
              {this.renderLatestGrade()}
              {this.props.submission && (
                <Flex.Item as="div" align="end" textAlign="end">
                  <Flex direction="column">
                    {this.isSubmissionLate() && (
                      <Flex.Item grow>
                        <LatePolicyStatusDisplay
                          attempt={this.props.submission.attempt}
                          gradingType={this.props.assignment.gradingType}
                          pointsPossible={this.props.assignment.pointsPossible}
                          originalGrade={this.props.submission.enteredGrade}
                          pointsDeducted={this.props.submission.deductedPoints}
                          grade={this.props.submission.grade}
                        />
                      </Flex.Item>
                    )}
                    <Flex.Item padding="xx-small" grow>
                      <SubmissionStatusPill
                        submissionStatus={this.props.submission.submissionStatus}
                      />
                    </Flex.Item>
                    <Flex.Item grow>
                      <CommentsTray
                        submission={this.props.submission}
                        assignment={this.props.assignment}
                        open={this.state.commentsTrayOpen}
                        closeTray={this.closeCommentsTray}
                      />
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              )}
            </Flex.Item>
          </Flex>
          {this.props.submission && !this.props.assignment.nonDigitalSubmission && (
            <Flex alignItems="center">
              <Flex.Item grow>
                <Flex>
                  {this.props.allSubmissions && (
                    <Flex.Item>
                      <AttemptSelect
                        allSubmissions={this.props.allSubmissions}
                        onChangeSubmission={this.props.onChangeSubmission}
                        submission={this.props.submission}
                      />
                    </Flex.Item>
                  )}

                  {this.props.assignment.env.currentUser && !lockAssignment && (
                    <Flex.Item>
                      <SubmissionWorkflowTracker submission={this.props.submission} />
                    </Flex.Item>
                  )}
                </Flex>
              </Flex.Item>

              <Flex.Item shrink>
                <Flex as="div">
                  {(this.props.submission.state === 'graded' ||
                    this.props.submission.state === 'submitted') && (
                    <Flex.Item margin="0 small 0 0">{this.selectedSubmissionGrade()}</Flex.Item>
                  )}
                  <Flex.Item>{this.renderViewFeedbackButton()}</Flex.Item>
                </Flex>
              </Flex.Item>
            </Flex>
          )}
        </div>
      </>
    )
  }
}

export default Header
