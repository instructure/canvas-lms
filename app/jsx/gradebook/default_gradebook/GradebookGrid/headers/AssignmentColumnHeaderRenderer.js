/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {isGraded, isPostable} from '../../../../grading/helpers/SubmissionHelper'
import {optionsForGradingType} from '../../../shared/EnterGradesAsSetting'
import AssignmentColumnHeader from './AssignmentColumnHeader'

function getSubmission(student, assignmentId) {
  const submission = student[`assignment_${assignmentId}`]

  if (!submission) {
    return {
      excused: false,
      hasPostableComments: false,
      latePolicyStatus: null,
      postedAt: null,
      score: null,
      submittedAt: null
    }
  }

  return {
    excused: submission.excused,
    hasPostableComments: submission.has_postable_comments,
    latePolicyStatus: submission.late_policy_status,
    postedAt: submission.posted_at,
    score: submission.score,
    submittedAt: submission.submitted_at,
    workflowState: submission.workflow_state
  }
}

function getProps(column, gradebook, options) {
  const assignmentId = column.assignmentId
  const columnId = column.id
  const sortRowsBySetting = gradebook.getSortRowsBySetting()
  const assignment = gradebook.getAssignment(column.assignmentId)

  const gradeSortDataLoaded =
    gradebook.contentLoadStates.assignmentsLoaded &&
    gradebook.contentLoadStates.studentsLoaded &&
    gradebook.contentLoadStates.submissionsLoaded

  const visibleStudentsForAssignment = Object.values(
    gradebook.studentsThatCanSeeAssignment(assignmentId)
  )
  const students = visibleStudentsForAssignment.map(student => ({
    id: student.id,
    isInactive: student.isInactive,
    isTestStudent: student.enrollments[0].type === 'StudentViewEnrollment',
    name: student.name,
    sortableName: student.sortable_name,
    submission: getSubmission(student, assignmentId)
  }))

  const hasGradesOrPostableComments = students.some(
    student => isGraded(student.submission) || student.submission.hasPostableComments
  )

  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav.addGradebookElement,

    assignment: {
      anonymizeStudents: assignment.anonymize_students,
      courseId: assignment.course_id,
      htmlUrl: assignment.html_url,
      id: assignment.id,
      muted: assignment.muted,
      name: assignment.name,
      pointsPossible: assignment.points_possible,
      postManually: assignment.post_manually,
      published: assignment.published,
      submissionTypes: assignment.submission_types
    },

    curveGradesAction: gradebook.getCurveGradesAction(assignmentId),
    downloadSubmissionsAction: gradebook.getDownloadSubmissionsAction(assignmentId),

    enterGradesAsSetting: {
      hidden: optionsForGradingType(assignment.grading_type).length < 2, // show only multiple options
      onSelect(value) {
        gradebook.updateEnterGradesAsSetting(assignmentId, value)
      },
      selected: gradebook.getEnterGradesAsSetting(assignmentId),
      showGradingSchemeOption: optionsForGradingType(assignment.grading_type).includes(
        'gradingScheme'
      )
    },

    onHeaderKeyDown: event => {
      gradebook.handleHeaderKeyDown(event, columnId)
    },
    onMenuDismiss() {
      setTimeout(gradebook.handleColumnHeaderMenuClose)
    },

    hideGradesAction: {
      hasGradesOrPostableComments,
      hasGradesOrCommentsToHide: students.some(student => student.submission.postedAt != null),
      onSelect(onExited) {
        if (gradebook.postPolicies) {
          gradebook.postPolicies.showHideAssignmentGradesTray({assignmentId, onExited})
        }
      }
    },

    includeSpeedGraderMenuItem: gradebook.options.include_speed_grader_in_assignment_header_menu,

    postGradesAction: {
      featureEnabled: gradebook.postPolicies != null,
      hasGradesOrPostableComments,
      hasGradesOrCommentsToPost: students.some(student => isPostable(student.submission)),
      newIconsEnabled: !!gradebook.options.new_post_policy_icons_enabled,
      onSelect(onExited) {
        if (gradebook.postPolicies) {
          gradebook.postPolicies.showPostAssignmentGradesTray({assignmentId, onExited})
        }
      }
    },

    removeGradebookElement: gradebook.keyboardNav.removeGradebookElement,
    reuploadSubmissionsAction: gradebook.getReuploadSubmissionsAction(assignmentId),
    setDefaultGradeAction: gradebook.getSetDefaultGradeAction(assignmentId),

    showGradePostingPolicyAction: {
      onSelect(onExited) {
        if (gradebook.postPolicies) {
          gradebook.postPolicies.showAssignmentPostingPolicyTray({assignmentId, onExited})
        }
      }
    },

    showUnpostedMenuItem: gradebook.options.new_gradebook_development_enabled,

    sortBySetting: {
      direction: sortRowsBySetting.direction,
      disabled: !gradeSortDataLoaded || assignment.anonymize_students,
      isSortColumn: sortRowsBySetting.columnId === columnId,
      onSortByGradeAscending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
      },
      onSortByGradeDescending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'descending')
      },
      onSortByLate: () => {
        gradebook.setSortRowsBySetting(columnId, 'late', 'ascending')
      },
      onSortByMissing: () => {
        gradebook.setSortRowsBySetting(columnId, 'missing', 'ascending')
      },
      onSortByUnposted: () => {
        gradebook.setSortRowsBySetting(columnId, 'unposted', 'ascending')
      },
      settingKey: sortRowsBySetting.settingKey
    },

    students,
    submissionsLoaded: gradebook.contentLoadStates.submissionsLoaded
  }
}

export default class AssignmentColumnHeaderRenderer {
  constructor(gradebook) {
    this.gradebook = gradebook
  }

  render(column, $container, _gridSupport, options) {
    const props = getProps(column, this.gradebook, options)
    ReactDOM.render(<AssignmentColumnHeader {...props} />, $container)
  }

  destroy(column, $container, _gridSupport) {
    ReactDOM.unmountComponentAtNode($container)
  }
}
