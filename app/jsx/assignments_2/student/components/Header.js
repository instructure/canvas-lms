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

import React from 'react'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import I18n from 'i18n!assignments_2_student_header'

import AssignmentGroupModuleNav from './AssignmentGroupModuleNav'
import SubmissionStatusPill from './SubmissionStatusPill'
import DateTitle from './DateTitle'
import PointsDisplay from './PointsDisplay'
import StepContainer from './StepContainer'
import Attempt from './Attempt'
import {number} from 'prop-types'

import {StudentAssignmentShape} from '../assignmentData'

class Header extends React.Component {
  static propTypes = {
    assignment: StudentAssignmentShape,
    scrollThreshold: number.isRequired
  }

  state = {
    isSticky: false
  }

  componentDidMount() {
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

  render() {
    return (
      <div
        data-test-id="assignments-2-student-header"
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
        <Flex margin={this.state.isSticky ? '0' : '0 0 medium 0'}>
          <FlexItem grow>
            <DateTitle assignment={this.props.assignment} />
          </FlexItem>
          <FlexItem grow>
            <PointsDisplay
              displayAs={this.props.assignment.gradingType}
              receivedGrade={
                this.props.assignment.submissionsConnection &&
                this.props.assignment.submissionsConnection.nodes[0] &&
                this.props.assignment.submissionsConnection.nodes[0].grade
              }
              possiblePoints={this.props.assignment.pointsPossible}
            />
            <FlexItem as="div" align="end" textAlign="end">
              <SubmissionStatusPill
                submissionStatus={
                  this.props.assignment.submissionsConnection &&
                  this.props.assignment.submissionsConnection.nodes[0] &&
                  this.props.assignment.submissionsConnection.nodes[0].submissionStatus
                }
              />
            </FlexItem>
          </FlexItem>
        </Flex>
        {!this.state.isSticky && <Attempt assignment={this.props.assignment} />}
        <div className="assignment-pizza-header-outer">
          <div
            className="assignment-pizza-header-inner"
            data-test-id={
              this.state.isSticky
                ? 'assignment-student-header-sticky'
                : 'assignment-student-header-normal'
            }
          >
            <StepContainer
              assignment={this.props.assignment}
              isCollapsed={this.state.isSticky}
              collapsedLabel={I18n.t('Submitted')}
            />
          </div>
        </div>
      </div>
    )
  }
}

export default Header
