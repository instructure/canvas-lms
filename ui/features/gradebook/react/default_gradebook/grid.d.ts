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

import type {GradebookStudent} from './gradebook.d'
import type {SubmissionCommentCamelized} from '@canvas/grading/grading.d'
import type {StatusColors} from './constants/colors'
import type LongTextEditor from '../../jquery/slickgrid.long_text_editor'

export type GridColumn = {id: string; cssClass: string; headerCssClass: string} & Partial<{
  assignmentGroupId: string
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
  width: number
  object: Partial<{
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
}>

export type GridData = {
  columns: {
    definitions: {
      // Add later: total_grade?: GridColumn
      // Add later: total_grade_override?: GridColumn
      [key: string]: GridColumn
    }
    frozen: string[]
    scrollable: string[]
  }
  rows: GradebookStudent[]
}

export type RowFilterKey = 'sectionId' | 'studentGroupId'

export type ColumnFilterKey =
  | 'assignmentGroupId'
  | 'contextModuleId'
  | 'gradingPeriodId'
  | 'submissions'
  | 'startDate'
  | 'endDate'

export type FilterColumnsOptions = {
  assignmentGroupId: null | string
  contextModuleId: null | string
  gradingPeriodId: null | string
  submissions: null | 'has-ungraded-submissions' | 'has-submissions'
  startDate: null | string
  endDate: null | string
}

export type GridDisplaySettings = {
  colors: StatusColors
  enterGradesAs: string
  filterColumnsBy: FilterColumnsOptions
  filterRowsBy: {sectionId: string | null; studentGroupId: string | null}
  hideTotal: boolean
  selectedPrimaryInfo: 'last_first' | 'first_last'
  selectedSecondaryInfo: string
  selectedViewOptionsFilters: string[]
  showEnrollments: {concluded: boolean; inactive: boolean}
  sortRowsBy: {
    columnId: string // the column controlling the sort
    settingKey: string // the key describing the sort criteria
    direction: 'ascending' | 'descending' // the direction of the sort
  }
  submissionTray: {
    open: boolean
    studentId: string
    assignmentId: string
    comments: SubmissionCommentCamelized[]
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
