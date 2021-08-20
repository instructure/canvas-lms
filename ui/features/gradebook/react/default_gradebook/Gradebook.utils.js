/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import assignmentHelper from '../shared/helpers/assignmentHelper'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import I18n from 'i18n!gradebook'
import _ from 'lodash'
import htmlEscape from 'html-escape'
import natcompare from '@canvas/util/natcompare'

export function compareAssignmentDueDates(assignment1, assignment2) {
  return assignmentHelper.compareByDueDate(assignment1.object, assignment2.object)
}

export function ensureAssignmentVisibility(assignment, submission) {
  if (
    assignment?.only_visible_to_overrides &&
    !assignment.assignment_visibility.includes(submission.user_id)
  ) {
    return assignment.assignment_visibility.push(submission.user_id)
  }
}

export function forEachSubmission(students, fn) {
  Object.keys(students).forEach(function (studentIdx) {
    const student = students[studentIdx]
    Object.keys(student).forEach(function (key) {
      const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/
      if (key.match(ASSIGNMENT_KEY_REGEX)) {
        fn(student[key])
      }
    })
  })
}

export function getAssignmentGroupPointsPossible(assignmentGroup) {
  return assignmentGroup.assignments.reduce(function (sum, assignment) {
    return sum + (assignment.points_possible || 0)
  }, 0)
}

export function getCourseFeaturesFromOptions(options) {
  return {
    finalGradeOverrideEnabled: options.final_grade_override_enabled,
    allowViewUngradedAsZero: !!options.allow_view_ungraded_as_zero
  }
}

export function getCourseFromOptions(options) {
  return {
    id: options.context_id
  }
}

export function getGradeAsPercent(grade) {
  if (grade.possible > 0) {
    // TODO: use GradeCalculationHelper.divide here
    return (grade.score || 0) / grade.possible
  } else {
    return null
  }
}

export function getStudentGradeForColumn(student, field) {
  return student[field] || {score: null, possible: 0}
}

export function htmlDecode(input) {
  return input && new DOMParser().parseFromString(input, 'text/html').documentElement.textContent
}

export function isAdmin() {
  return (ENV.current_user_roles || []).includes('admin')
}

export function onGridKeyDown(event, obj) {
  if (obj.row == null || obj.cell == null) {
    return
  }

  const columns = obj.grid.getColumns()
  const column = columns[obj.cell]

  if (!column) {
    return
  }

  if (column.type === 'student' && event.which === 13) {
    // activate link
    event.originalEvent.skipSlickGridDefaults = true
  }
}

export function renderComponent(reactClass, mountPoint, props = {}, children = null) {
  const component = React.createElement(reactClass, props, children)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(component, mountPoint)
}

export function compareAssignmentPositions(a, b) {
  const diffOfAssignmentGroupPosition =
    a.object.assignment_group.position - b.object.assignment_group.position
  const diffOfAssignmentPosition = a.object.position - b.object.position
  // order first by assignment_group position and then by assignment position
  // will work when there are less than 1000000 assignments in an assignment_group
  return diffOfAssignmentGroupPosition * 1000000 + diffOfAssignmentPosition
}

export async function confirmViewUngradedAsZero({currentValue, onAccepted}) {
  const showDialog = () =>
    showConfirmationDialog({
      body: I18n.t(
        'This setting only affects your view of student grades and displays grades as if all ungraded assignments were given a score of zero. This setting is a visual change only and does not affect grades for students or other users of this Gradebook. When this setting is enabled, Canvas will not populate zeros in the Gradebook for student submissions within individual assignments. Only the assignment groups and total columns will automatically factor scores of zero into the overall percentages for each student.'
      ),
      confirmText: I18n.t('OK'),
      label: I18n.t('View Ungraded as Zero')
    })

  // If the setting was already enabled, no need to show the confirmation
  // dialog since we're turning it off
  const userAccepted = currentValue || (await showDialog())
  if (userAccepted) {
    onAccepted()
  }
}

export function isDefaultSortOrder(sortOrder) {
  return !['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder)
}

export function hiddenStudentIdsForAssignment(studentIds, assignment) {
  return _.difference(studentIds, assignment.assignment_visibility)
}

export function localeSort(a, b, {asc = true, nullsLast = false} = {}) {
  if (nullsLast) {
    if (a != null && b == null) {
      return -1
    }
    if (a == null && b != null) {
      return 1
    }
  }
  if (!asc) {
    ;[b, a] = [a, b]
  }
  return natcompare.strings(a || '', b || '')
}

export function getDefaultSettingKeyForColumnType(columnType) {
  if (
    columnType === 'assignment' ||
    columnType === 'assignment_group' ||
    columnType === 'total_grade'
  ) {
    return 'grade'
  } else if (columnType === 'student') {
    return 'sortable_name'
  }
}

export function sectionList(sections) {
  return _.values(sections)
    .sort((a, b) => {
      return a.id - b.id
    })
    .map(section => {
      return {...section, name: htmlEscape.unescape(section.name)}
    })
}

export function compareAssignmentPointsPossible(a, b) {
  return a.object.points_possible - b.object.points_possible
}
