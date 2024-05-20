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

import type {
  GradebookStudent,
  SubmissionFilterValue,
  SerializedComment,
  SortRowsSettingKey,
} from './gradebook.d'
import type {GradeEntryMode} from '@canvas/grading/grading.d'
import type {StatusColors} from './constants/colors'
import type LongTextEditor from '../../jquery/slickgrid.long_text_editor'

export type GridColumnObject = Partial<{
  id: string
  due_at: string | null
  name: string
  position: number
  points_possible: number
  module_ids: string[]
  module_positions: number[]
  assignment_group: {
    position: number
  }
}>

export type GridColumn = {
  id: string
  cssClass: string
  headerCssClass: string
  object: GridColumnObject
  width: number
} & Partial<{
  assignmentGroupId: string
  assignmentId: string
  autoEdit: boolean
  customColumnId: string
  editor: LongTextEditor
  field: string
  hidden: boolean
  maxLength: number
  maxWidth: number
  minWidth: number
  postAssignmentGradesTrayOpenForAssignmentId: boolean
  resizable: boolean
  teacher_notes: string
  toolTip: string
  type: string
}>

export type GridDataColumns = {
  definitions: {
    // Add later: total_grade?: GridColumn
    // Add later: total_grade_override?: GridColumn
    [key: string]: GridColumn
  }
  frozen: string[]
  scrollable: string[]
}

export type GridDataColumnsWithObjects = {
  definitions: {
    [key: string]: GridColumn
  }
  frozen: {
    id: string
    customColumnId: string
    type: 'custom_column'
  }[]
  scrollable: {
    id: string
    customColumnId: string
    type: 'custom_column'
  }[]
}

export type GridData = {
  columns: GridDataColumns
  rows: GradebookStudent[]
}

export type RowFilterKey = 'sectionId' | 'studentGroupId' | 'studentGroupIds'

export type ColumnFilterKey =
  | 'assignmentGroupId'
  | 'assignmentGroupIds'
  | 'contextModuleId'
  | 'contextModuleIds'
  | 'gradingPeriodId'
  | 'submissions'
  | 'submissionFilters'
  | 'startDate'
  | 'endDate'

export type FilterColumnsOptions = {
  assignmentGroupId: null | string
  assignmentGroupIds: null | string[]
  contextModuleId: null | string
  contextModuleIds: null | string[]
  gradingPeriodId: null | string
  submissions: null | SubmissionFilterValue
  submissionFilters: null | SubmissionFilterValue[]
  startDate: null | string
  endDate: null | string
}

export type FilterRowsBy = {
  sectionId: string | null
  sectionIds: string[] | null
  studentGroupId: string | null
  studentGroupIds: string[] | null
}

export type FilterColumnsBy = {}

export type GridDisplaySettings = {
  colors: StatusColors
  enterGradesAs: {
    [assignmentId: string]: GradeEntryMode
  }
  filterColumnsBy: FilterColumnsOptions
  filterRowsBy: FilterRowsBy
  hideTotal: boolean
  selectedPrimaryInfo: 'last_first' | 'first_last'
  selectedSecondaryInfo: string
  selectedViewOptionsFilters: string[]
  showEnrollments: {concluded: boolean; inactive: boolean}
  sortRowsBy: {
    columnId: string // the column controlling the sort
    settingKey: SortRowsSettingKey // the key describing the sort criteria
    direction: 'ascending' | 'descending' // the direction of the sort
  }
  submissionTray: {
    open: boolean
    studentId: string
    assignmentId: string
    comments: SerializedComment[]
    commentsLoaded: boolean
    commentsUpdating: boolean
    editedCommentId: string | null
  }
  viewUngradedAsZero: boolean
  showUnpublishedAssignments: boolean
  showSeparateFirstLastNames: boolean
  hideAssignmentGroupTotals: boolean
  hideAssignmentGroupTotals: boolean
  hideTotal: boolean
}

export type GridLocation = {
  columnId: string
  region: 'body' | 'header' | 'footer'
}

export type SlickGridKeyboardEvent = KeyboardEvent & {
  originalEvent: {skipSlickGridDefaults?: boolean | undefined}
}
