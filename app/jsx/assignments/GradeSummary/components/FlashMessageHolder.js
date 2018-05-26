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
import {oneOf} from 'prop-types'
import {connect} from 'react-redux'
import I18n from 'i18n!assignment_grade_summary'

import {showFlashAlert} from '../../../shared/FlashAlert'
import * as AssignmentActions from '../assignment/AssignmentActions'
import * as StudentActions from '../students/StudentActions'

function enumeratedStatuses(actions) {
  return [actions.FAILURE, actions.STARTED, actions.SUCCESS]
}

const assignmentStatuses = [
  AssignmentActions.FAILURE,
  AssignmentActions.GRADES_ALREADY_PUBLISHED,
  AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE,
  AssignmentActions.STARTED,
  AssignmentActions.SUCCESS
]

function announcePublishGradesStatus(status) {
  let message, type

  switch (status) {
    case AssignmentActions.SUCCESS:
      message = I18n.t('Grades were successfully published to the gradebook.')
      type = 'success'
      break
    case AssignmentActions.GRADES_ALREADY_PUBLISHED:
      message = I18n.t('Assignment grades have already been published.')
      type = 'error'
      break
    case AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE:
      message = I18n.t('All submissions must have a selected grade.')
      type = 'error'
      break
    case AssignmentActions.FAILURE:
      message = I18n.t('There was a problem publishing grades.')
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
      type: 'success'
    })
  } else if (status === AssignmentActions.FAILURE) {
    showFlashAlert({
      message: I18n.t('There was a problem updating the assignment.'),
      type: 'error'
    })
  }
}

class FlashMessageHolder extends Component {
  static propTypes = {
    loadStudentsStatus: oneOf(enumeratedStatuses(StudentActions)),
    publishGradesStatus: oneOf(assignmentStatuses),
    unmuteAssignmentStatus: oneOf(enumeratedStatuses(AssignmentActions))
  }

  static defaultProps = {
    loadStudentsStatus: null,
    publishGradesStatus: null,
    unmuteAssignmentStatus: null
  }

  componentWillReceiveProps(nextProps) {
    const changes = Object.keys(nextProps).reduce(
      (changeMap, prop) => ({...changeMap, [prop]: nextProps[prop] !== this.props[prop]}),
      {}
    )

    if (changes.loadStudentsStatus) {
      if (nextProps.loadStudentsStatus === StudentActions.FAILURE) {
        showFlashAlert({
          message: I18n.t('There was a problem loading students.'),
          type: 'error'
        })
      }
    }

    if (changes.publishGradesStatus) {
      announcePublishGradesStatus(nextProps.publishGradesStatus)
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
    loadStudentsStatus: state.students.loadStudentsStatus,
    publishGradesStatus: state.assignment.publishGradesStatus,
    unmuteAssignmentStatus: state.assignment.unmuteAssignmentStatus
  }
}

export default connect(mapStateToProps)(FlashMessageHolder)
