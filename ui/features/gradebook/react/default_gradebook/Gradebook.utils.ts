/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import LongTextEditor from '../../jquery/slickgrid.long_text_editor'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import getTextWidth from '../shared/helpers/TextMeasure'
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'lodash'
import htmlEscape from 'html-escape'
import filterTypes from './constants/filterTypes'
import type {
  CustomColumn,
  ColumnSizeSettings,
  Filter,
  FilterType,
  FilterPreset,
  GradebookFilterApiRequest,
  GradebookFilterApiResponse,
  PartialFilterPreset,
  SubmissionFilterValue
} from './gradebook.d'
import type {
  Assignment,
  AssignmentGroup,
  GradingPeriod,
  Module,
  Section,
  StudentGroup,
  StudentGroupCategory,
  StudentMap,
  Submission
} from '../../../../api.d'
import type {GridColumn} from './grid'
import {columnWidths} from './initialState'

const I18n = useI18nScope('gradebook')

const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/

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

export function forEachSubmission(students: StudentMap, fn) {
  Object.keys(students).forEach(function (studentIdx) {
    const student = students[studentIdx]
    Object.keys(student).forEach(function (key) {
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

export function getColumnTypeForColumnId(columnId: string): string {
  if (columnId.match(/^custom_col/)) {
    return 'custom_column'
  } else if (columnId.match(ASSIGNMENT_KEY_REGEX)) {
    return 'assignment'
  } else if (columnId.match(/^assignment_group/)) {
    return 'assignment_group'
  } else {
    return columnId
  }
}

export function getDefaultSettingKeyForColumnType(columnType: string) {
  if (
    columnType === 'assignment' ||
    columnType === 'assignment_group' ||
    columnType === 'total_grade'
  ) {
    return 'grade'
  }
  // default value for other column types
  return 'sortable_name'
}

export function sectionList(sections: {[id: string]: Pick<Section, 'name' | 'id'>}) {
  const x: Pick<Section, 'name' | 'id'>[] = _.values(sections)
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

export function findFilterValuesOfType(type: FilterType, appliedFilters: Filter[]) {
  return appliedFilters.reduce(
    (values: string[], filter: Filter) =>
      filter.type === type && filter.value ? values.concat(filter.value) : values,
    []
  )
}

export function findSubmissionFilterValue(appliedFilters: Filter[]) {
  const values = findFilterValuesOfType('submissions', appliedFilters)
  return (
    values.length && ['has-ungraded-submissions', 'has-submissions'].includes(values[0])
      ? values[0]
      : undefined
  ) as SubmissionFilterValue
}

// Extra normalization; comes from jsonb payload
export const deserializeFilter = (json: GradebookFilterApiResponse): FilterPreset => {
  const filterPreset = json.gradebook_filter
  if (!filterPreset.id || typeof filterPreset.id !== 'string') throw new Error('invalid filter id')
  if (!Array.isArray(filterPreset.payload.conditions))
    throw new Error('invalid filter preset filters (conditions)')
  const filters = filterPreset.payload.conditions
    .filter(c => c && (typeof c.type === 'undefined' || filterTypes.includes(c.type)))
    .map(c => ({
      id: c.id,
      type: c.type,
      value: c.value,
      created_at: String(c.created_at)
    }))
  return {
    id: filterPreset.id,
    name: String(filterPreset.name),
    filters,
    created_at: String(filterPreset.created_at),
    updated_at: String(filterPreset.updated_at)
  }
}

export const serializeFilter = (filterPreset: PartialFilterPreset): GradebookFilterApiRequest => {
  return {
    name: filterPreset.name,
    payload: {
      conditions: filterPreset.filters
    }
  }
}

export const compareFilterSetByUpdatedDate = (a: FilterPreset, b: FilterPreset) =>
  new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()

export const getLabelForFilter = (
  filter: Filter,
  assignmentGroups: Pick<AssignmentGroup, 'id' | 'name'>[],
  gradingPeriods: Pick<GradingPeriod, 'id' | 'title'>[],
  modules: Pick<Module, 'id' | 'name'>[],
  sections: Pick<Section, 'id' | 'name'>[],
  studentGroupCategories: StudentGroupCategory[]
) => {
  if (!filter.type) throw new Error('missing condition type')

  if (filter.type === 'section') {
    return sections.find(s => s.id === filter.value)?.name || I18n.t('Section')
  } else if (filter.type === 'module') {
    return modules.find(m => m.id === filter.value)?.name || I18n.t('Module')
  } else if (filter.type === 'assignment-group') {
    return assignmentGroups.find(a => a.id === filter.value)?.name || I18n.t('Assignment Group')
  } else if (filter.type === 'grading-period') {
    return gradingPeriods.find(g => g.id === filter.value)?.title || I18n.t('Grading Period')
  } else if (filter.type === 'student-group') {
    const studentGroups: StudentGroup[] = Object.values(studentGroupCategories)
      .map((c: StudentGroupCategory) => c.groups)
      .flat()
    return (
      studentGroups.find((g: StudentGroup) => g.id === filter.value)?.name ||
      I18n.t('Student Group')
    )
  } else if (filter.type === 'submissions') {
    if (filter.value === 'has-ungraded-submissions') {
      return I18n.t('Has ungraded submissions')
    } else if (filter.value === 'has-submissions') {
      return I18n.t('Has submissions')
    } else {
      throw new Error('invalid submissions filter value')
    }
  } else if (filter.type === 'start-date') {
    const options: any = {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric'
    }
    if (typeof filter.value !== 'string') throw new Error('invalid start-date value')
    const value = Intl.DateTimeFormat(I18n.currentLocale(), options).format(new Date(filter.value))
    return I18n.t('Start Date %{value}', {value})
  } else if (filter.type === 'end-date') {
    const options: any = {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric'
    }
    if (typeof filter.value !== 'string') throw new Error('invalid end-date value')
    const value = Intl.DateTimeFormat(I18n.currentLocale(), options).format(new Date(filter.value))
    return I18n.t('End Date %{value}', {value})
  }

  // unrecognized types should have been filtered out by deserializeFilter
  throw new Error('invalid filter type')
}

export const isFilterNotEmpty = (filter: Filter) => {
  return filter.value && filter.value !== '__EMPTY__'
}

export function doFiltersMatch(filters1: Filter[], filters2: Filter[]) {
  const filtersWithValues1 = filters1.filter(isFilterNotEmpty)
  const filtersWithValues2 = filters2.filter(isFilterNotEmpty)
  return (
    filtersWithValues1.length > 0 &&
    filtersWithValues1.length === filtersWithValues2.length &&
    filtersWithValues1.every(c1 =>
      filtersWithValues2.some(c2 => c2.type === c1.type && c2.value === c1.value)
    )
  )
}

// logic taken from needs_grading_conditions in submission.rb
export function doesSubmissionNeedGrading(s: Submission) {
  if (s.excused) return false

  if (s.workflow_state === 'pending_review') return true

  if (!['submitted', 'graded'].includes(s.workflow_state)) return false

  if (!s.grade_matches_current_submission) return true

  return typeof s.score !== 'number'
}

export function assignmentSearchMatcher(
  option: {
    label: string
  },
  searchTerm: string
): boolean {
  const term = searchTerm?.toLowerCase() || ''
  const assignmentName = option.label?.toLowerCase() || ''
  return assignmentName.includes(term)
}

export function buildStudentColumn(
  columnId: string,
  gradebookColumnSizeSetting: string,
  defaultWidth: number
): GridColumn {
  const studentColumnWidth = gradebookColumnSizeSetting
    ? parseInt(gradebookColumnSizeSetting, 10)
    : defaultWidth
  return {
    id: columnId,
    type: columnId,
    width: studentColumnWidth,
    cssClass: 'meta-cell primary-column student',
    headerCssClass: 'primary-column student',
    resizable: true
  }
}

export function buildCustomColumn(customColumn: CustomColumn): GridColumn {
  const columnId = getCustomColumnId(customColumn.id)
  return {
    id: columnId,
    type: 'custom_column',
    field: `custom_col_${customColumn.id}`,
    width: 100,
    cssClass: `meta-cell custom_column ${columnId}`,
    headerCssClass: `custom_column ${columnId}`,
    resizable: true,
    editor: LongTextEditor,
    customColumnId: customColumn.id,
    autoEdit: false,
    maxLength: 255
  }
}

export const buildAssignmentGroupColumnFn =
  (gradebookColumnSizeSettings: ColumnSizeSettings) =>
  (assignmentGroup: Pick<AssignmentGroup, 'id' | 'name'>): GridColumn => {
    let width
    const columnId = getAssignmentGroupColumnId(assignmentGroup.id)
    const fieldName = `assignment_group_${assignmentGroup.id}`
    if (gradebookColumnSizeSettings && gradebookColumnSizeSettings[fieldName]) {
      width = parseInt(gradebookColumnSizeSettings[fieldName], 10)
    } else {
      width = testWidth(
        assignmentGroup.name,
        columnWidths.assignmentGroup.min,
        columnWidths.assignmentGroup.default_max
      )
    }
    return {
      id: columnId,
      field: fieldName,
      toolTip: assignmentGroup.name,
      object: assignmentGroup,
      minWidth: columnWidths.assignmentGroup.min,
      maxWidth: columnWidths.assignmentGroup.max,
      width,
      cssClass: `meta-cell assignment-group-cell ${columnId}`,
      headerCssClass: `assignment_group ${columnId}`,
      type: 'assignment_group',
      assignmentGroupId: assignmentGroup.id
    }
  }

const HEADER_START_AND_END_WIDTHS_IN_PIXELS = 36
export function testWidth(text: string, minWidth: number, maxWidth: number) {
  const padding = HEADER_START_AND_END_WIDTHS_IN_PIXELS * 2
  const textWidth = getTextWidth(text) || 0
  const width = Math.max(textWidth + padding, minWidth)
  return Math.min(width, maxWidth)
}
