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

import AssignmentGroupModuleNav from './AssignmentGroupModuleNav'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import AttemptSelect from './AttemptSelect'
import AssignmentDetails from './AssignmentDetails'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'
import GradeDisplay from './GradeDisplay'
import {Badge} from '@instructure/ui-badge'
import {Heading} from '@instructure/ui-heading'
import {IconChatLine} from '@instructure/ui-icons'
import I18n from 'i18n!assignments_2_student_header'
import LatePolicyStatusDisplay from './LatePolicyStatusDisplay/index'
import {number, arrayOf, func} from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import SubmissionStatusPill from '@canvas/assignments/react/SubmissionStatusPill'
import SubmissionWorkflowTracker from './SubmissionWorkflowTracker'
import CommentsTray from './CommentsTray/index'

class Header extends React.Component {
  static propTypes = {
    allSubmissions: arrayOf(Submission.shape),
    assignment: Assignment.shape,
    onChangeSubmission: func,
    scrollThreshold: number.isRequired,
    submission: Submission.shape
  }

  static defaultProps = {
    scrollThreshold: 150,
    onChangeSubmission: () => {}
  }

  state = {
    isSticky: false,
    nonStickyHeaderheight: 0,
    commentsTrayOpen: false
  }

  componentDidMount() {
    const nonStickyHeaderheight = document.getElementById('assignments-2-student-header')
      .clientHeight
    this.setState({nonStickyHeaderheight})
    window.addEventListener('scroll', this.handleScroll)
  }

  componentWillUnmount() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  handleScroll = () => {
    if (window.pageYOffset < this.props.scrollThreshold) {
      this.setState({isSticky: false})
    } else {
      this.setState({isSticky: true})
    }
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

  renderFakeMostRecent = () => {
    return (
      <Flex.Item as="div" align="end" textAlign="end">
        {I18n.t('Calculated by: ')}
        <div>{I18n.t('Most Recent')}</div>
      </Flex.Item>
    )
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
          data-testid={
            this.state.isSticky
              ? 'assignment-student-header-sticky'
              : 'assignment-student-header-normal'
          }
          id="assignments-2-student-header"
          className={
            this.state.isSticky
              ? 'assignment-student-header-sticky'
              : 'assignment-student-header-normal'
          }
        >
          <Heading level="h1">
            {/* We hide this because in the designs, what visually looks like should
              be the h1 appears after the group/module links, but we need the
              h1 to actually come before them for a11y */}
            <ScreenReaderContent> {this.props.assignment.name} </ScreenReaderContent>
          </Heading>

          {!this.state.isSticky && <AssignmentGroupModuleNav assignment={this.props.assignment} />}
          <Flex wrap="wrap" alignItems="start" wrapItems>
            <Flex.Item shrink>
              <AssignmentDetails
                isSticky={this.state.isSticky}
                assignment={this.props.assignment}
              />
            </Flex.Item>
            <Flex.Item grow align="start">
              {this.renderLatestGrade()}
              {this.renderFakeMostRecent()}
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

              <Flex.Item>{this.renderViewFeedbackButton()}</Flex.Item>
            </Flex>
          )}
        </div>
        {
          // We need this element to fill the gap that is missing when the regular
          // header is removed in the transtion to the sticky header
        }
        {this.state.isSticky && (
          <div
            data-testid="header-element-filler"
            style={{height: `${this.state.nonStickyHeaderheight - this.props.scrollThreshold}px`}}
          />
        )}
      </>
    )
  }
}

export default Header
