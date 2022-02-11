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
// @ts-ignore
import I18n from 'i18n!gradebook'
import _ from 'lodash'
import htmlEscape from 'html-escape'
import type {
  Assignment,
  Filter,
  GradebookFilterApiResponse,
  GradebookFilterApiRequest,
  PartialFilter,
  Section,
  SectionMap,
  Submission
} from './gradebook.d'

export function compareAssignmentDueDates(assignment1, assignment2) {
  return assignmentHelper.compareByDueDate(assignment1.object, assignment2.object)
}

export function ensureAssignmentVisibility(assignment: Assignment, submission: Submission) {
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

export function getStudentGradeForColumn(student, field: string) {
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

export function renderComponent(reactClass, mountPoint, props = {}, children: any = null) {
  const component = React.createElement(reactClass, props, children)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(component, mountPoint)
}

export async function confirmViewUngradedAsZero({currentValue, onAccepted}) {
  const showDialog = () =>
    showConfirmationDialog({
      body: I18n.t(
        'This setting only affects your view of student grades and displays grades as if all ungraded assignments were given a score of zero. This setting is a visual change only and does not affect grades for students or other users of this Gradebook. When this setting is enabled, Canvas will not populate zeros in the Gradebook for student submissions within individual assignments. Only the assignment groups and total columns will automatically factor scores of zero into the overall percentages for each student.'
      ),
      confirmText: I18n.t('OK'),
      label: I18n.t('View Ungraded as Zero'),
      confirmColor: undefined
    })

  // If the setting was already enabled, no need to show the confirmation
  // dialog since we're turning it off
  const userAccepted = currentValue || (await showDialog())
  if (userAccepted) {
    onAccepted()
  }
}

export function hiddenStudentIdsForAssignment(studentIds: string[], assignment: Assignment) {
  return _.difference(studentIds, assignment.assignment_visibility)
}

export function getDefaultSettingKeyForColumnType(columnType: string) {
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

export function sectionList(sections: SectionMap) {
  const x: Section[] = _.values(sections)
  return x
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(section => {
      return {...section, name: htmlEscape.unescape(section.name)}
    })
}

export function getCustomColumnId(customColumnId: string) {
  return `custom_col_${customColumnId}`
}

export function getAssignmentColumnId(assignmentId: string) {
  return `assignment_${assignmentId}`
}

export function getAssignmentGroupColumnId(assignmentGroupId: string) {
  return `assignment_group_${assignmentGroupId}`
}

export function findAllAppliedFilterValuesOfType(type: string, filters: Filter[]) {
  return filters
    .filter(f => f.is_applied)
    .flatMap(f => f.conditions.filter(c => c.type === type && c.value))
    .map(c => c.value)
}

export function getAllAppliedFilterValues(filters: Filter[]) {
  return filters
    .filter(f => f.is_applied)
    .flatMap(f => f.conditions.filter(c => c.value))
    .map(c => c.value)
}

// Extra normalization; comes from jsonb payload
export const deserializeFilter = (json: GradebookFilterApiResponse): Filter => {
  const filter = json.gradebook_filter
  if (!filter.id || typeof filter.id !== 'string') throw new Error('invalid filter id')
  if (!Array.isArray(filter.payload.conditions)) throw new Error('invalid filter conditions')
  const conditions = filter.payload.conditions.map(c => {
    if (!c || typeof c.id !== 'string') throw new Error('invalid condition id')
    return {
      id: c.id,
      type: c.type,
      value: c.value,
      created_at: String(c.created_at)
    }
  })
  return {
    id: filter.id,
    name: String(filter.name),
    conditions,
    is_applied: !!filter.payload.is_applied,
    created_at: String(filter.created_at)
  }
}

export const serializeFilter = (filter: PartialFilter): GradebookFilterApiRequest => {
  return {
    name: filter.name,
    payload: {
      is_applied: filter.is_applied,
      conditions: filter.conditions
    }
  }
}

export const compareFilterByDate = (a: Filter, b: Filter) =>
  new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
