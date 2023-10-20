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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {objectOf, arrayOf, func, oneOf, shape, string, number, bool} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'

import {useScope as useI18nScope} from '@canvas/i18n'

import * as AssignmentActions from '../assignment/AssignmentActions'
import GradersTable from './GradersTable/index'
import PostToStudentsButton from './PostToStudentsButton'
import ReleaseButton from './ReleaseButton'
import {
  SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
  setReleaseGradesStatus,
} from '../assignment/AssignmentActions'

const I18n = useI18nScope('assignment_grade_summary')

/* eslint-disable no-alert */

function enumeratedStatuses(actions) {
  return [
    actions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
    actions.FAILURE,
    actions.STARTED,
    actions.SUCCESS,
  ]
}

function validGradersSelected(gradesByStudentId) {
  return Object.values(gradesByStudentId).every(gradesByGraderId => {
    const grades = Object.values(gradesByGraderId)
    const selectedGrade = grades.find(grade => grade.selected)
    if (!selectedGrade) {
      return true
    }
    const graderFound = ENV.GRADERS.find(grader => selectedGrade.graderId === grader.user_id)
    return !graderFound || graderFound.grader_selectable
  })
}

class Header extends Component {
  static propTypes = {
    assignment: shape({
      title: string.isRequired,
    }).isRequired,
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired,
      })
    ).isRequired,
    releaseGrades: func.isRequired,
    releaseGradesStatus: oneOf(enumeratedStatuses(AssignmentActions)),
    unmuteAssignment: func.isRequired,
    unmuteAssignmentStatus: oneOf(enumeratedStatuses(AssignmentActions)),
    provisionalGrades: objectOf(
      objectOf(
        shape({
          grade: string,
          graderId: string.isRequired,
          id: string.isRequired,
          score: number,
          selected: bool.isRequired,
          studentId: string.isRequired,
        })
      )
    ).isRequired,
    setReleaseGradesStatus: func.isRequired,
  }

  static defaultProps = {
    releaseGradesStatus: null,
    unmuteAssignmentStatus: null,
  }

  handleReleaseClick = () => {
    const message = I18n.t(
      'Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.'
    )

    // This is stupid, but Chrome has an issue whereby confirm alerts sometimes just
    // cancel themselves in certain cases.
    // See https://stackoverflow.com/questions/51250430/chrome-dismisses-confirm-promps-immediately-without-any-user-interaction
    setTimeout(() => {
      if (window.confirm(message)) this.props.releaseGrades()
    }, 100)
  }

  handleUnmuteClick = () => {
    const message = I18n.t('Are you sure you want to post grades for this assignment to students?')

    // This is stupid, but Chrome has an issue whereby confirm alerts sometimes just
    // cancel themselves in certain cases.
    // See https://stackoverflow.com/questions/51250430/chrome-dismisses-confirm-promps-immediately-without-any-user-interaction
    setTimeout(() => {
      if (window.confirm(message)) this.props.unmuteAssignment()
    }, 100)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    if (nextProps.provisionalGrades !== this.props.provisionalGrades) {
      this.updateStatus(nextProps)
    }
  }

  updateStatus = nextProps => {
    const isValidSelection = validGradersSelected(nextProps.provisionalGrades)
    const status = !isValidSelection ? SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS : null
    const shouldUpdateStatus = nextProps.releaseGradesStatus !== status
    if (shouldUpdateStatus) {
      this.props.setReleaseGradesStatus(status)
    }
  }

  render() {
    return (
      <header>
        {this.props.assignment.gradesPublished && (
          <Alert margin="0 0 medium 0" variant="info">
            <Text weight="bold">{I18n.t('Attention!')}</Text>{' '}
            {I18n.t('Grades cannot be modified from this page as they have already been released.')}
          </Alert>
        )}
        {this.props.releaseGradesStatus ===
          AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS && (
          <Alert margin="0 0 medium 0" variant="error">
            {I18n.t(
              'One or more grade selected was provided by a grader with inactive enrollments. Please update your selections to those provided by current graders.'
            )}
          </Alert>
        )}

        <Heading level="h1" margin="0 0 x-small 0">
          {I18n.t('Grade Summary')}
        </Heading>

        <Text size="x-large">{this.props.assignment.title}</Text>

        <Flex as="div" margin="large 0 0 0">
          {this.props.graders.length > 0 && (
            <Flex.Item as="div" flex="1" shouldGrow={true}>
              <GradersTable />
            </Flex.Item>
          )}

          <Flex.Item align="end" as="div" flex="2" shouldGrow={true}>
            <Flex as="div" justifyItems="end">
              <Flex.Item>
                <ReleaseButton
                  gradesReleased={this.props.assignment.gradesPublished}
                  margin="0 x-small 0 0"
                  onClick={this.handleReleaseClick}
                  releaseGradesStatus={this.props.releaseGradesStatus}
                />
              </Flex.Item>

              <Flex.Item>
                <PostToStudentsButton
                  assignment={this.props.assignment}
                  onClick={this.handleUnmuteClick}
                  unmuteAssignmentStatus={this.props.unmuteAssignmentStatus}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </header>
    )
  }
}

function mapStateToProps(state) {
  const {assignment, releaseGradesStatus, unmuteAssignmentStatus} = state.assignment

  return {
    assignment,
    graders: state.context.graders,
    releaseGradesStatus,
    unmuteAssignmentStatus,
    provisionalGrades: state.grades.provisionalGrades,
  }
}

function mapDispatchToProps(dispatch) {
  return {
    releaseGrades() {
      dispatch(AssignmentActions.releaseGrades())
    },
    unmuteAssignment() {
      dispatch(AssignmentActions.unmuteAssignment())
    },

    setReleaseGradesStatus(status) {
      dispatch(setReleaseGradesStatus(status))
    },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Header)
/* eslint-enable no-alert */
