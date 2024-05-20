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
import htmlEscape, {unescape} from '@instructure/html-escape'
import filterTypes from './constants/filterTypes'
import type {
  ColumnSizeSettings,
  CustomColumn,
  CustomStatusIdString,
  EnrollmentFilter,
  Filter,
  FilterPreset,
  FilterType,
  GradebookFilterApiRequest,
  GradebookFilterApiResponse,
  GradebookStudent,
  GradebookStudentMap,
  GradingPeriodAssignmentMap,
  PartialFilterPreset,
  SortRowsSettingKey,
  SubmissionFilterValue,
} from './gradebook.d'
import type {
  Assignment,
  AssignmentGroup,
  GradingPeriod,
  MissingSubmission,
  Module,
  Section,
  Student,
  StudentGroup,
  StudentGroupCategory,
  StudentGroupCategoryMap,
  Submission,
  SubmissionType,
} from '../../../../api.d'
import type {GridColumn, SlickGridKeyboardEvent} from './grid'
import {columnWidths} from './initialState'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = useI18nScope('gradebook')

const createDateTimeFormatter = (timeZone: string) => {
  return Intl.DateTimeFormat(I18n.currentLocale(), {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    timeZone,
  })
}

const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/

export function compareAssignmentDueDates(assignment1: GridColumn, assignment2: GridColumn) {
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

export function forEachSubmission(
  students: GradebookStudentMap,
  fn: (submission: Submission) => void
) {
  Object.keys(students).forEach(function (studentIdx) {
    const student = students[studentIdx]
    Object.keys(student).forEach(function (key) {
      if (key.match(ASSIGNMENT_KEY_REGEX)) {
        const submission = student[key] as Submission
        fn(submission)
      }
    })
  })
}

export function getAssignmentGroupPointsPossible(assignmentGroup: AssignmentGroup) {
  return assignmentGroup.assignments.reduce(function (sum: number, assignment) {
    return sum + (assignment.points_possible || 0)
  }, 0)
}

export function getCourseFeaturesFromOptions(options: {
  final_grade_override_enabled: boolean
  allow_view_ungraded_as_zero: boolean
}) {
  return {
    finalGradeOverrideEnabled: options.final_grade_override_enabled,
    allowViewUngradedAsZero: Boolean(options.allow_view_ungraded_as_zero),
  }
}

export function getCourseFromOptions(options: {context_id: string}) {
  return {
    id: options.context_id,
  }
}

export function getGradeAsPercent(grade: {score?: number | null; possible: number}) {
  if (grade.possible > 0) {
    // TODO: use GradeCalculationHelper.divide here
    return (grade.score || 0) / grade.possible
  } else {
    return null
  }
}

export function getStudentGradeForColumn(student: GradebookStudent, field: string) {
  return student[field] || {score: null, possible: 0}
}

export function idArraysEqual(idArray1: string[], idArray2: string[]): boolean {
  return [...idArray1].sort().join() === [...idArray2].sort().join()
}

export function htmlDecode(input?: string): string | null {
  return input
    ? new DOMParser().parseFromString(input, 'text/html').documentElement.textContent
    : null
}

export function isAdmin() {
  return (ENV.current_user_roles || []).includes('admin')
}

export function onGridKeyDown(
  event: SlickGridKeyboardEvent,
  obj: {
    row: number | null
    cell: number | null
    grid: {
      getColumns(): GridColumn[]
    }
  }
) {
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

export function renderComponent(
  reactClass: any,
  mountPoint: Element | null,
  props = {}
): HTMLElement | undefined {
  if (mountPoint == null) {
    throw new Error('mountPoint is required')
  }
  const component = React.createElement(reactClass, props)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(component, mountPoint)
}

export async function confirmViewUngradedAsZero({
  currentValue,
  onAccepted,
}: {
  currentValue: boolean
  onAccepted: () => void
}) {
  const showDialog = () =>
    showConfirmationDialog({
      body: I18n.t(
        'This setting only affects your view of student grades and displays grades as if all ungraded assignments were given a score of zero. This setting is a visual change only and does not affect grades for students or other users of this Gradebook. When this setting is enabled, Canvas will not populate zeros in the Gradebook for student submissions within individual assignments. Only the assignment groups and total columns will automatically factor scores of zero into the overall percentages for each student.'
      ),
      confirmText: I18n.t('OK'),
      label: I18n.t('View Ungraded as Zero'),
      confirmColor: undefined,
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

export function getDefaultSettingKeyForColumnType(columnType: string): SortRowsSettingKey {
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
      return {...section, name: unescape(section.name)}
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
    values.length &&
    [
      'has-ungraded-submissions',
      'has-submissions',
      'has-no-submissions',
      'has-unposted-grades',
      'late',
      'missing',
      'resubmitted',
      'dropped',
      'excused',
      'extended',
    ].includes(values[0])
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
      created_at: String(c.created_at),
    }))
  return {
    id: filterPreset.id,
    name: String(filterPreset.name),
    filters,
    created_at: String(filterPreset.created_at),
    updated_at: String(filterPreset.updated_at),
  }
}

export const serializeFilter = (filterPreset: PartialFilterPreset): GradebookFilterApiRequest => {
  return {
    name: filterPreset.name,
    payload: {
      conditions: filterPreset.filters,
    },
  }
}

export const compareFilterSetByUpdatedDate = (a: FilterPreset, b: FilterPreset) => {
  return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
}

export const mapCustomStatusToIdString = (customStatus: GradeStatus): CustomStatusIdString => {
  return `custom-status-${customStatus.id}`
}

export const getCustomStatusIdStrings = (customStatuses: GradeStatus[]): CustomStatusIdString[] => {
  return customStatuses.map(status => mapCustomStatusToIdString(status))
}

export const getLabelForFilter = (
  filter: Filter,
  assignmentGroups: Pick<AssignmentGroup, 'id' | 'name'>[],
  gradingPeriods: Pick<GradingPeriod, 'id' | 'title'>[],
  modules: Pick<Module, 'id' | 'name'>[],
  sections: Pick<Section, 'id' | 'name'>[],
  studentGroupCategories: StudentGroupCategoryMap,
  customStatuses: GradeStatus[]
) => {
  const customStatusesMap = customStatuses.reduce((acc, status) => {
    acc[mapCustomStatusToIdString(status)] = status.name
    return acc
  }, {} as Record<CustomStatusIdString, string>)
  if (!filter.type) throw new Error('missing condition type')

  if (filter.type === 'section') {
    return sections.find(s => s.id === filter.value)?.name || I18n.t('Section')
  } else if (filter.type === 'module') {
    return modules.find(m => m.id === filter.value)?.name || I18n.t('Module')
  } else if (filter.type === 'assignment-group') {
    return assignmentGroups.find(a => a.id === filter.value)?.name || I18n.t('Assignment Group')
  } else if (filter.type === 'grading-period') {
    if (filter.value === '0') return I18n.t('All Grading Periods')
    return (
      formatGradingPeriodTitleForDisplay(gradingPeriods.find(g => g.id === filter.value)) ||
      I18n.t('Grading Period')
    )
  } else if (filter.type === 'student-group') {
    const studentGroups: StudentGroup[] = Object.values(studentGroupCategories)
      .map((c: StudentGroupCategory) => c.groups)
      .flat()
    return (
      studentGroups.find((g: StudentGroup) => g.id === filter.value)?.name ||
      I18n.t('Student Group')
    )
  } else if (filter.type === 'submissions') {
    if (!filter.value) {
      throw new Error('missing submissions filter value')
    }
    const filterNameMap: Record<string, string> = {
      'has-ungraded-submissions': I18n.t('Has ungraded submissions'),
      'has-submissions': I18n.t('Has submissions'),
      'has-no-submissions': I18n.t('Has no submissions'),
      'has-unposted-grades': I18n.t('Has unposted grades'),
      late: I18n.t('Late'),
      missing: I18n.t('Missing'),
      resubmitted: I18n.t('Resubmitted'),
      dropped: I18n.t('Dropped'),
      excused: I18n.t('Excused'),
      extended: I18n.t('Extended'),
      ...customStatusesMap,
    }
    if (filter.value in filterNameMap) {
      return filterNameMap[filter.value]
    } else {
      throw new Error('invalid submissions filter value')
    }
  } else if (filter.type === 'start-date') {
    if (typeof filter.value !== 'string') throw new Error('invalid start-date value')
    const value = createDateTimeFormatter(ENV.TIMEZONE).format(new Date(filter.value))
    return I18n.t('Start Date %{value}', {value})
  } else if (filter.type === 'end-date') {
    if (typeof filter.value !== 'string') throw new Error('invalid end-date value')
    const value = createDateTimeFormatter(ENV.TIMEZONE).format(new Date(filter.value))
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
export function doesSubmissionNeedGrading(s: Submission | MissingSubmission) {
  if (s.excused) return false

  if (s.workflow_state === 'pending_review') return true

  if (!['submitted', 'graded'].includes(s.workflow_state || '')) return false

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
  let studentColumnWidth = gradebookColumnSizeSetting
    ? parseInt(gradebookColumnSizeSetting, 10)
    : defaultWidth
  if (Number.isNaN(studentColumnWidth)) {
    studentColumnWidth = defaultWidth
    // eslint-disable-next-line no-console
    console.warn('invalid student column width')
  }
  return {
    cssClass: 'meta-cell primary-column student',
    headerCssClass: 'primary-column student',
    id: columnId,
    object: {},
    resizable: true,
    type: columnId,
    width: studentColumnWidth,
  }
}

export function buildCustomColumn(customColumn: CustomColumn): GridColumn {
  const columnId = getCustomColumnId(customColumn.id)
  return {
    autoEdit: false,
    cssClass: `meta-cell custom_column ${columnId}`,
    customColumnId: customColumn.id,
    editor: LongTextEditor,
    field: `custom_col_${customColumn.id}`,
    headerCssClass: `custom_column ${columnId}`,
    id: columnId,
    object: {},
    maxLength: 255,
    resizable: true,
    type: 'custom_column',
    width: 100,
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
      assignmentGroupId: assignmentGroup.id,
    }
  }

const HEADER_START_AND_END_WIDTHS_IN_PIXELS = 36
export function testWidth(text: string, minWidth: number, maxWidth: number) {
  const padding = HEADER_START_AND_END_WIDTHS_IN_PIXELS * 2
  const textWidth = getTextWidth(text) || 0
  const width = Math.max(textWidth + padding, minWidth)
  return Math.min(width, maxWidth)
}

export function otherGradingPeriodAssignmentIds(
  gradingPeriodAssignments: GradingPeriodAssignmentMap,
  selectedAssignmentIds: string[],
  selectedPeriodId: string
) {
  const restIds = Object.values(gradingPeriodAssignments)
    .flat()
    .filter((id: string) => !selectedAssignmentIds.includes(id))

  return {
    otherAssignmentIds: [...new Set(restIds)],
    otherGradingPeriodIds: Object.keys(gradingPeriodAssignments).filter(
      gpId => gpId !== selectedPeriodId
    ),
  }
}

const createQueryString = ([key, val]: [
  string,
  string | number | boolean | string[] | SubmissionType[]
]): string => {
  if (Array.isArray(val)) {
    return val.map(v => createQueryString([`${key}[]`, String(v)])).join('&')
  }

  return `${encodeURIComponent(key)}=${encodeURIComponent(val)}`
}

const DEFAULT_REQUEST_CHARACTER_LIMIT = 8000 // apache limit

export function maxAssignmentCount(
  params: {
    include: string[]
    override_assignment_dates: boolean
    exclude_response_fields: string[]
    exclude_assignment_submission_types: SubmissionType[]
    per_page: number
    assignment_ids?: string
  },
  pathName: string,
  requestCharacterLimit: number = DEFAULT_REQUEST_CHARACTER_LIMIT
) {
  const queryString = Object.entries(params).map(createQueryString).join('&')
  const currentURI = `${window.location.hostname}${pathName}?${queryString}`
  const charsAvailable = requestCharacterLimit - `${currentURI}&assignment_ids=`.length
  const globalIdLength = 8
  const assignmentParam = encodeURIComponent(`${'0'.repeat(globalIdLength)},`)

  return Math.floor(charsAvailable / assignmentParam.length)
}

// mutative
export function escapeStudentContent(student: Student) {
  const unescapedName = student.name
  const unescapedSortableName = student.sortable_name
  const unescapedFirstName = student.first_name
  const unescapedLastName = student.last_name

  for (const key in student) {
    if (Object.prototype.hasOwnProperty.call(student, key)) {
      ;(student as any)[key] = htmlEscape((student as any)[key])
    }
  }
  const escapedStudent: Student = student

  escapedStudent.name = unescapedName
  escapedStudent.sortable_name = unescapedSortableName
  escapedStudent.first_name = unescapedFirstName
  escapedStudent.last_name = unescapedLastName

  escapedStudent?.enrollments.forEach(enrollment => {
    const gradesUrl = enrollment?.grades?.html_url
    if (gradesUrl) {
      enrollment.grades.html_url = unescape(gradesUrl)
    }
  })
}

export function isGradedOrExcusedSubmissionUnposted(submission: Submission | MissingSubmission) {
  return (
    submission.posted_at === null &&
    ((submission.score !== null && submission.workflow_state === 'graded') || submission.excused)
  )
}

export const wasSubmitted = (s: Submission | MissingSubmission) =>
  Boolean(s.submitted_at) && !['unsubmitted', 'deleted'].includes(s.workflow_state || '')

// filters should run either .some() or .every()
export const categorizeFilters = (appliedFilters: Filter[], customStatuses: GradeStatus[]) => {
  const submissionFilters = findFilterValuesOfType(
    'submissions',
    appliedFilters
  ) as SubmissionFilterValue[]
  const customStatusIds = getCustomStatusIdStrings(customStatuses)

  const possibleSomeFilters = [
    'dropped',
    'excused',
    'extended',
    'has-submissions',
    'has-ungraded-submissions',
    'has-unposted-grades',
    'late',
    'missing',
    'resubmitted',
    ...customStatusIds,
  ]

  let filtersNeedingEvery: SubmissionFilterValue[] = []

  const {multiselect_gradebook_filters_enabled} = ENV.GRADEBOOK_OPTIONS ?? {}

  if (multiselect_gradebook_filters_enabled) {
    possibleSomeFilters.push('has-no-submissions')
  } else {
    filtersNeedingEvery = submissionFilters.filter(filter =>
      ['has-no-submissions'].includes(filter)
    )
  }

  const filtersNeedingSome: SubmissionFilterValue[] = submissionFilters.filter(filter =>
    possibleSomeFilters.includes(filter)
  )

  return {filtersNeedingSome, filtersNeedingEvery}
}

export function filterSubmission(
  filters: SubmissionFilterValue[],
  submission: Submission | MissingSubmission,
  customStatuses: GradeStatus[]
) {
  if (filters.length === 0) {
    return true
  }
  const customStatusIds = getCustomStatusIdStrings(customStatuses)

  const {multiselect_gradebook_filters_enabled} = ENV.GRADEBOOK_OPTIONS ?? {}
  const filterOperation = multiselect_gradebook_filters_enabled ? 'some' : 'every'

  return filters[filterOperation](filter => {
    if (filter === 'has-ungraded-submissions') {
      return doesSubmissionNeedGrading(submission)
    } else if (filter === 'has-submissions') {
      return wasSubmitted(submission)
    } else if (filter === 'has-no-submissions') {
      return !wasSubmitted(submission)
    } else if (filter === 'has-unposted-grades') {
      return isGradedOrExcusedSubmissionUnposted(submission)
    } else if (filter === 'late') {
      return Boolean(submission.late)
    } else if (filter === 'missing') {
      return Boolean(submission.missing)
    } else if (filter === 'resubmitted') {
      return submission.grade_matches_current_submission === false
    } else if (filter === 'dropped') {
      return Boolean(submission.drop)
    } else if (filter === 'excused') {
      return submission.excused
    } else if (filter === 'extended') {
      return submission.late_policy_status === 'extended'
    } else if (customStatusIds.includes(filter)) {
      return `custom-status-${submission.custom_grade_status_id}` === filter
    } else {
      return false
    }
  })
}

export function filterSubmissionsByCategorizedFilters(
  filtersNeedingSome: SubmissionFilterValue[],
  filtersNeedingEvery: SubmissionFilterValue[],
  submissions: (Submission | MissingSubmission)[],
  customStatuses: GradeStatus[]
) {
  const hasMatch =
    submissions.some(submission =>
      filterSubmission(filtersNeedingSome, submission, customStatuses)
    ) &&
    submissions.every(submission =>
      filterSubmission(filtersNeedingEvery, submission, customStatuses)
    )

  return hasMatch
}

export const filterStudentBySubmissionFn = (
  appliedFilters: Filter[],
  submissionStateMap: SubmissionStateMap,
  assignmentIds: string[],
  customStatuses: GradeStatus[]
) => {
  const submissionFilters = findFilterValuesOfType(
    'submissions',
    appliedFilters
  ) as SubmissionFilterValue[]

  return (student: Student) => {
    if (submissionFilters.length === 0) {
      return true
    }

    const submissions = submissionStateMap.getSubmissionsByStudentAndAssignmentIds(
      student.id,
      assignmentIds
    )

    // when sorting rows, we only use .some to determine visiblity
    return filterSubmissionsByCategorizedFilters(submissionFilters, [], submissions, customStatuses)
  }
}

const getIncludedEnrollmentStates = (enrollmentFilter: EnrollmentFilter) => {
  const enrollmentStates = ['active', 'invited']
  if (enrollmentFilter.inactive) {
    enrollmentStates.push('inactive')
  }
  if (enrollmentFilter.concluded) {
    enrollmentStates.push('completed')
  }
  return enrollmentStates
}

export const filterStudentBySectionFn = (
  appliedFilters: Filter[],
  enrollmentFilter: EnrollmentFilter
) => {
  const sectionFilters = findFilterValuesOfType(
    'section',
    appliedFilters
  ) as SubmissionFilterValue[]

  return (student: Student) => {
    if (sectionFilters.length === 0) {
      return true
    }
    const {multiselect_gradebook_filters_enabled} = ENV.GRADEBOOK_OPTIONS ?? {}
    const includedEnrollmentStates = getIncludedEnrollmentStates(enrollmentFilter)
    const sectionFiltersToApply = multiselect_gradebook_filters_enabled
      ? sectionFilters
      : [sectionFilters[0]]
    const enrollmentStates = student.enrollments
      .filter(e => sectionFiltersToApply.includes(e.course_section_id as SubmissionFilterValue))
      .map(enrollment => enrollment.enrollment_state)
    return student.sections
      ? enrollmentStates.length > 0 &&
          _.intersection(enrollmentStates, includedEnrollmentStates).length > 0
      : false
  }
}

export const filterAssignmentsBySubmissionsFn = (
  appliedFilters: Filter[],
  submissionStateMap: SubmissionStateMap,
  searchFilteredStudentIds: string[],
  customStatuses: GradeStatus[]
) => {
  const {filtersNeedingSome, filtersNeedingEvery} = categorizeFilters(
    appliedFilters,
    customStatuses
  )

  return (assignment: Assignment) => {
    if (filtersNeedingSome.length === 0 && filtersNeedingEvery.length === 0) {
      return true
    }

    let submissions = submissionStateMap.getSubmissionsByAssignment(assignment.id)

    if (searchFilteredStudentIds.length > 0) {
      submissions = submissions.filter(submission =>
        searchFilteredStudentIds.includes(submission.user_id)
      )
    }

    const result = filterSubmissionsByCategorizedFilters(
      filtersNeedingSome,
      filtersNeedingEvery,
      submissions,
      customStatuses
    )
    return result
  }
}
export function formatGradingPeriodTitleForDisplay(
  gradingPeriod: GradingPeriod | undefined | null
) {
  if (!gradingPeriod) return null

  let title = gradingPeriod.title

  if (ENV.GRADEBOOK_OPTIONS?.grading_periods_filter_dates_enabled) {
    const formatter = Intl.DateTimeFormat(I18n.currentLocale(), {
      year: '2-digit',
      month: 'numeric',
      day: 'numeric',
      timezone: ENV.TIMEZONE,
    })

    title = I18n.t('%{title}: %{start} - %{end} | %{closed}', {
      title: gradingPeriod.title,
      start: formatter.format(gradingPeriod.startDate),
      end: formatter.format(gradingPeriod.endDate),
      closed: formatter.format(gradingPeriod.closeDate),
    })
  }

  return title
}
