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

import type {Student} from './gradebook.d'
import type {StatusColors} from './constants/colors'

type GridColumn = {
  id: string
  type: string
  field?: string
  width: number
  hidden?: boolean
  cssClass: string
  headerCssClass: string
  customColumnId?: string
  teacher_notes?: string
  resizable?: boolean
  postAssignmentGradesTrayOpenForAssignmentId?: string
}

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
  rows: Student[]
}

export type GridDisplaySettings = {
  colors: StatusColors
  enterGradesAs: string
  filterColumnsBy: {
    assignmentGroupId: null | string
    contextModuleId: null | string
    gradingPeriodId: null | string
    submissions: null | 'has-ungraded-submissions' | 'has-submissions'
  }
  filterColumnsBy: {assignmentGroupId: null; contextModuleId: null; gradingPeriodId: null}
  filterRowsBy: {sectionId: null; studentGroupId: null}
  hideTotal: boolean
  selectedPrimaryInfo: string
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
    studentId: null | string
    assignmentId: null | string
    comments: any[]
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
