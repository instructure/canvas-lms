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

import {Component} from 'react'
import {arrayOf, bool, oneOf, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import * as AssignmentActions from '../assignment/AssignmentActions'
import * as GradeActions from '../grades/GradeActions'
import * as StudentActions from '../students/StudentActions'

const I18n = useI18nScope('assignment_grade_summary')

function enumeratedStatuses(actions) {
  return [actions.FAILURE, actions.STARTED, actions.SUCCESS]
}

const assignmentStatuses = [
  AssignmentActions.FAILURE,
  AssignmentActions.GRADES_ALREADY_RELEASED,
  AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE,
  AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
  AssignmentActions.STARTED,
  AssignmentActions.SUCCESS,
]

function announceReleaseGradesStatus(status) {
  let message, type

  switch (status) {
    case AssignmentActions.SUCCESS:
      message = I18n.t('Grades were successfully released to the gradebook.')
      type = 'success'
      break
    case AssignmentActions.GRADES_ALREADY_RELEASED:
      message = I18n.t('Assignment grades have already been released.')
      type = 'error'
      break
    case AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE:
      message = I18n.t('All submissions must have a selected grade.')
      type = 'error'
      break
    case AssignmentActions.FAILURE:
      message = I18n.t('There was a problem releasing grades.')
      type = 'error'
      break
    default:
      return
  }

  showFlashAlert({message, type})
}

function announceUnmuteAssignmentStatus(status) {
  if (status === AssignmentActions.SUCCESS) {
    showFlashAlert({
      message: I18n.t('Grades for this assignment are now visible to students.'),
      type: 'success',
    })
  } else if (status === AssignmentActions.FAILURE) {
    showFlashAlert({
      message: I18n.t('There was a problem updating the assignment.'),
      type: 'error',
    })
  }
}

class FlashMessageHolder extends Component {
  static propTypes = {
    bulkSelectProvisionalGradeStatuses: shape({}).isRequired,
    loadStudentsStatus: oneOf(enumeratedStatuses(StudentActions)),
    releaseGradesStatus: oneOf(assignmentStatuses),
    selectProvisionalGradeStatuses: shape({}).isRequired,
    unmuteAssignmentStatus: oneOf(enumeratedStatuses(AssignmentActions)),
    updateGradeStatuses: arrayOf(
      shape({
        gradeInfo: shape({
          studentId: string.isRequired,
          selected: bool,
        }).isRequired,
        status: oneOf(enumeratedStatuses(StudentActions)),
      })
    ).isRequired,
  }

  static defaultProps = {
    loadStudentsStatus: null,
    releaseGradesStatus: null,
    unmuteAssignmentStatus: null,
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    const changes = Object.keys(nextProps).reduce(
      (changeMap, prop) => ({...changeMap, [prop]: nextProps[prop] !== this.props[prop]}),
      {}
    )

    if (changes.loadStudentsStatus) {
      if (nextProps.loadStudentsStatus === StudentActions.FAILURE) {
        showFlashAlert({
          message: I18n.t('There was a problem loading students.'),
          type: 'error',
        })
      }
    }

    if (changes.selectProvisionalGradeStatuses) {
      Object.keys(nextProps.selectProvisionalGradeStatuses).forEach(studentId => {
        if (
          nextProps.selectProvisionalGradeStatuses[studentId] !==
          this.props.selectProvisionalGradeStatuses[studentId]
        ) {
          const status = nextProps.selectProvisionalGradeStatuses[studentId]
          if (status === GradeActions.SUCCESS) {
            showFlashAlert({
              message: I18n.t('Grade saved.'),
              type: 'success',
            })
          } else if (status === GradeActions.FAILURE) {
            showFlashAlert({
              message: I18n.t('There was a problem saving the grade.'),
              type: 'error',
            })
          }
        }
      })
    }

    if (changes.bulkSelectProvisionalGradeStatuses) {
      Object.keys(nextProps.bulkSelectProvisionalGradeStatuses).forEach(graderId => {
        if (
          nextProps.bulkSelectProvisionalGradeStatuses[graderId] !==
          this.props.bulkSelectProvisionalGradeStatuses[graderId]
        ) {
          const status = nextProps.bulkSelectProvisionalGradeStatuses[graderId]
          if (status === GradeActions.SUCCESS) {
            showFlashAlert({
              message: I18n.t('Grades saved.'),
              type: 'success',
            })
          } else if (status === GradeActions.FAILURE) {
            showFlashAlert({
              message: I18n.t('There was a problem saving the grades.'),
              type: 'error',
            })
          }
        }
      })
    }

    if (changes.updateGradeStatuses) {
      const newStatuses = nextProps.updateGradeStatuses.filter(
        statusInfo => this.props.updateGradeStatuses.indexOf(statusInfo) === -1
      )
      newStatuses.forEach(statusInfo => {
        if (statusInfo.status === GradeActions.SUCCESS && statusInfo.gradeInfo.selected) {
          showFlashAlert({
            message: I18n.t('Grade saved.'),
            type: 'success',
          })
        } else if (statusInfo.status === GradeActions.FAILURE) {
          showFlashAlert({
            message: I18n.t('There was a problem updating the grade.'),
            type: 'error',
          })
        }
      })
    }

    if (changes.releaseGradesStatus) {
      announceReleaseGradesStatus(nextProps.releaseGradesStatus)
    }

    if (changes.unmuteAssignmentStatus) {
      announceUnmuteAssignmentStatus(nextProps.unmuteAssignmentStatus)
    }
  }

  render() {
    return null
  }
}

function mapStateToProps(state) {
  return {
    bulkSelectProvisionalGradeStatuses: state.grades.bulkSelectProvisionalGradeStatuses,
    loadStudentsStatus: state.students.loadStudentsStatus,
    releaseGradesStatus: state.assignment.releaseGradesStatus,
    selectProvisionalGradeStatuses: state.grades.selectProvisionalGradeStatuses,
    unmuteAssignmentStatus: state.assignment.unmuteAssignmentStatus,
    updateGradeStatuses: state.grades.updateGradeStatuses,
  }
}

export default connect(mapStateToProps)(FlashMessageHolder)
