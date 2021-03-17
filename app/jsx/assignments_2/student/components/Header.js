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
import {Assignment} from '../graphqlData/Assignment'
import AttemptSelect from './AttemptSelect'
import AssignmentDetails from './AssignmentDetails'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import GradeDisplay from './GradeDisplay'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!assignments_2_student_header'
import LatePolicyStatusDisplay from './LatePolicyStatusDisplay'
import {number, arrayOf, func} from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StepContainer from './StepContainer'
import StudentViewContext from './Context'
import {Submission} from '../graphqlData/Submission'
import SubmissionStatusPill from '../../shared/SubmissionStatusPill'
import SubmissionWorkflowTracker from './SubmissionWorkflowTracker'

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
    nonStickyHeaderheight: 0
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
        const submission = context.latestSubmission || {grade: null, gradingStatus: null}
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

  shouldRenderNewAttempt(context) {
    const {assignment, submission} = this.props
    return (
      !assignment.lockInfo.isLocked &&
      (submission.state === 'graded' || submission.state === 'submitted') &&
      submission.gradingStatus !== 'excused' &&
      context.isLatestAttempt &&
      context.allowChangesToSubmission &&
      (assignment.allowedAttempts === null || submission.attempt < assignment.allowedAttempts)
    )
  }

  renderNewAttemptButton = () => (
    <StudentViewContext.Consumer>
      {context => {
        if (this.shouldRenderNewAttempt(context)) {
          return (
            <Button
              data-testid="new-attempt-button"
              color="primary"
              margin="small xxx-small"
              onClick={context.startNewAttemptAction}
            >
              {I18n.t('New Attempt')}
            </Button>
          )
        }
        return null
      }}
    </StudentViewContext.Consumer>
  )

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
          <Flex margin={this.state.isSticky ? '0' : '0 0 medium 0'} wrap="wrap" wrapItems>
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
                    <Flex.Item grow>
                      <SubmissionStatusPill
                        submissionStatus={this.props.submission.submissionStatus}
                      />
                    </Flex.Item>
                    <Flex.Item grow>
                      {!this.state.isSticky && this.renderNewAttemptButton()}
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              )}
            </Flex.Item>
          </Flex>

          {this.props.submission && (
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
