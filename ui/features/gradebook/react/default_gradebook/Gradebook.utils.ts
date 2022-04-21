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
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'lodash'
import htmlEscape from 'html-escape'
import type {
  Assignment,
  AssignmentGroup,
  Filter,
  FilterCondition,
  FilterConditionType,
  GradebookFilterApiRequest,
  GradebookFilterApiResponse,
  GradingPeriod,
  Module,
  PartialFilter,
  Section,
  SectionMap,
  StudentGroup,
  StudentGroupCategory,
  StudentGroupCategoryMap,
  Submission,
  SubmissionFilterConditionValue
} from './gradebook.d'
import filterConditionTypes from './constants/filterConditionTypes'

const I18n = useI18nScope('gradebook')

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

export function findConditionValuesOfType(
  type: FilterConditionType,
  appliedConditions: FilterCondition[]
) {
  return appliedConditions.reduce(
    (values: string[], condition: FilterCondition) =>
      condition.type === type && condition.value ? values.concat(condition.value) : values,
    []
  )
}

export function findSubmissionConditionValue(appliedConditions: FilterCondition[]) {
  const conditions = findConditionValuesOfType('submissions', appliedConditions)
  return (
    conditions.length && ['has-ungraded-submissions', 'has-submissions'].includes(conditions[0])
      ? conditions[0]
      : undefined
  ) as SubmissionFilterConditionValue
}

// Extra normalization; comes from jsonb payload
export const deserializeFilter = (json: GradebookFilterApiResponse): Filter => {
  const filter = json.gradebook_filter
  if (!filter.id || typeof filter.id !== 'string') throw new Error('invalid filter id')
  if (!Array.isArray(filter.payload.conditions)) throw new Error('invalid filter conditions')
  const conditions = filter.payload.conditions
    .filter(c => c && (typeof c.type === 'undefined' || filterConditionTypes.includes(c.type)))
    .map(c => ({
      id: c.id,
      type: c.type,
      value: c.value,
      created_at: String(c.created_at)
    }))
  return {
    id: filter.id,
    name: String(filter.name),
    conditions,
    created_at: String(filter.created_at)
  }
}

export const serializeFilter = (filter: PartialFilter): GradebookFilterApiRequest => {
  return {
    name: filter.name,
    payload: {
      conditions: filter.conditions
    }
  }
}

export const compareFilterByDate = (a: Filter, b: Filter) =>
  new Date(a.created_at).getTime() - new Date(b.created_at).getTime()

export const getLabelForFilterCondition = (
  condition: FilterCondition,
  assignmentGroups: Pick<AssignmentGroup, 'id' | 'name'>[],
  gradingPeriods: Pick<GradingPeriod, 'id' | 'title'>[],
  modules: Pick<Module, 'id' | 'name'>[],
  sections: Pick<Section, 'id' | 'name'>[],
  studentGroupCategories: StudentGroupCategoryMap
) => {
  if (!condition.type) throw new Error('missing condition type')

  if (condition.type === 'section') {
    return sections.find(s => s.id === condition.value)?.name || I18n.t('Section')
  } else if (condition.type === 'module') {
    return modules.find(m => m.id === condition.value)?.name || I18n.t('Module')
  } else if (condition.type === 'assignment-group') {
    return assignmentGroups.find(a => a.id === condition.value)?.name || I18n.t('Assignment Group')
  } else if (condition.type === 'grading-period') {
    return gradingPeriods.find(g => g.id === condition.value)?.title || I18n.t('Grading Period')
  } else if (condition.type === 'student-group') {
    const studentGroups: StudentGroup[] = Object.values(studentGroupCategories)
      .map((c: StudentGroupCategory) => c.groups)
      .flat()
    return (
      studentGroups.find((g: StudentGroup) => g.id === condition.value)?.name ||
      I18n.t('Student Group')
    )
  } else if (condition.type === 'submissions') {
    if (condition.value === 'has-ungraded-submissions') {
      return I18n.t('Has ungraded submissions')
    } else if (condition.value === 'has-submissions') {
      return I18n.t('Has submissions')
    } else {
      throw new Error('invalid submissions condition value')
    }
  } else if (condition.type === 'start-date') {
    const options: any = {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric'
    }
    if (typeof condition.value !== 'string') throw new Error('invalid start-date value')
    const value = Intl.DateTimeFormat(I18n.currentLocale(), options).format(
      new Date(condition.value)
    )
    return I18n.t('Start Date %{value}', {value})
  } else if (condition.type === 'end-date') {
    const options: any = {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric'
    }
    if (typeof condition.value !== 'string') throw new Error('invalid end-date value')
    const value = Intl.DateTimeFormat(I18n.currentLocale(), options).format(
      new Date(condition.value)
    )
    return I18n.t('End Date %{value}', {value})
  }

  // unrecognized types should have been filtered out by deserializeFilter
  throw new Error('invalid condition type')
}

export function doFilterConditionsMatch(
  conditions1: FilterCondition[],
  conditions2: FilterCondition[]
) {
  const conditionsWithValues1 = conditions1.filter(c => c.value)
  const conditionsWithValues2 = conditions2.filter(c => c.value)
  return (
    conditionsWithValues1.length > 0 &&
    conditionsWithValues1.length === conditionsWithValues2.length &&
    conditionsWithValues1.every(c1 =>
      conditionsWithValues2.some(c2 => c2.type === c1.type && c2.value === c1.value)
    )
  )
}
