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
import DateTitle from './DateTitle'
import {Flex} from '@instructure/ui-layout'
import GradeDisplay from './GradeDisplay'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!assignments_2_student_header'
import LatePolicyStatusDisplay from './LatePolicyStatusDisplay'
import {number, arrayOf, func} from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import StepContainer from './StepContainer'
import StudentViewContext from './Context'
import {Submission} from '../graphqlData/Submission'
import SubmissionStatusPill from '../../shared/SubmissionStatusPill'

class Header extends React.Component {
  static propTypes = {
    allSubmissions: arrayOf(Submission.shape),
    assignment: Assignment.shape,
    onChangeSubmission: func.isRequired,
    scrollThreshold: number.isRequired,
    submission: Submission.shape
  }

  static defaultProps = {
    scrollThreshold: 150
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

  /* eslint-disable jsx-a11y/anchor-is-valid */
  renderFakeMostRecent = () => {
    return (
      <Flex.Item as="div" align="end" textAlign="end">
        {I18n.t('Calculated by: ')}
        <a>{I18n.t('Most Recent')}</a>
      </Flex.Item>
    )
  }
  /* eslint-enable jsx-a11y/anchor-is-valid */

  renderLatestGrade = () => (
    <StudentViewContext.Consumer>
      {context => {
        const {latestSubmission} = context
        return (
          <GradeDisplay
            gradingType={this.props.assignment.gradingType}
            receivedGrade={latestSubmission ? latestSubmission.grade : null}
            pointsPossible={this.props.assignment.pointsPossible}
          />
        )
      }}
    </StudentViewContext.Consumer>
  )

  render() {
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
              <DateTitle isSticky={this.state.isSticky} assignment={this.props.assignment} />
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
                  </Flex>
                </Flex.Item>
              )}
            </Flex.Item>
          </Flex>
          {!this.state.isSticky && (
            <AttemptSelect
              allSubmissions={this.props.allSubmissions}
              onChangeSubmission={this.props.onChangeSubmission}
              submission={this.props.submission}
            />
          )}
          <div className="assignment-pizza-header-outer">
            <div
              className="assignment-pizza-header-inner"
              data-testid={
                this.state.isSticky
                  ? 'assignment-student-pizza-header-sticky'
                  : 'assignment-student-pizza-header-normal'
              }
            >
              <StepContainer
                assignment={this.props.assignment}
                submission={this.props.submission}
                forceLockStatus={
                  !this.props.assignment.env.currentUser || !!this.props.assignment.env.modulePrereq
                }
                isCollapsed={this.state.isSticky}
              />
            </div>
          </div>
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
