/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {DeprecatedGradingScheme, ProgressData} from '@canvas/grading/grading.d'
import {GradingStandard} from '@instructure/grading-utils'
import {
  AssignmentConnection,
  UserConnection,
  GradebookUserSubmissionDetails,
  SubmissionConnection,
} from './queries.d'
import {GradingPeriod, GradingPeriodSet} from '../../../api.d'

export enum GradebookSortOrder {
  DueDate = 'dueDate',
  Alphabetical = 'alphabetical',
  AssignmentGroup = 'assignmentGroup',
}

export type TeacherNotes = {
  id: string
  hidden: boolean
  position: number
  read_only: boolean
  teacher_notes: boolean
  title: string
}

export type CustomOptions = {
  includeUngradedAssignments: boolean
  hideStudentNames: boolean
  showConcludedEnrollments: boolean
  showNotesColumn: boolean
  showTotalGradeAsPoints: boolean
  allowFinalGradeOverride: boolean
}

export type CustomColumn = {
  id: string
  teacher_notes: boolean
  position: number
  title: string
  read_only: boolean
}

export type CustomColumnDatum = {
  content: string
  user_id: string
}

export type HandleCheckboxChange = (key: keyof CustomOptions, value: boolean) => void

export type GradebookOptions = {
  activeGradingPeriods?: GradingPeriod[]
  anonymizeStudents?: boolean
  sortOrder: GradebookSortOrder
  selectedSection?: string
  selectedGradingPeriodId?: string
  exportGradebookCsvUrl?: string
  lastGeneratedCsvAttachmentUrl?: string | null
  gradebookCsvProgress?: ProgressData | null
  contextUrl?: string | null
  userId?: string | null
  contextId?: string | null
  changeGradeUrl?: string | null
  customColumnDataUrl?: string | null
  customColumnDatumUrl?: string | null
  customColumnUrl?: string | null
  customColumnsUrl?: string | null
  gradeCalcIgnoreUnpostedAnonymousEnabled?: boolean | null
  gradesAreWeighted?: boolean | null
  gradingPeriodSet?: GradingPeriodSet | null
  gradingSchemes?: DeprecatedGradingScheme[] | null
  gradingStandard?: GradingStandard[] | null
  gradingStandardScalingFactor: number
  gradingStandardPointsBased: boolean
  groupWeightingScheme?: string | null
  finalGradeOverrideEnabled?: boolean | null
  proxySubmissionEnabled: boolean
  publishToSisEnabled?: boolean | null
  publishToSisUrl?: string | null
  reorderCustomColumnsUrl?: string | null
  saveViewUngradedAsZeroToServer?: boolean | null
  settingUpdateUrl?: string | null
  settingsUpdateUrl?: string | null
  teacherNotes?: TeacherNotes | null
  customOptions: CustomOptions
  showTotalGradeAsPoints?: boolean | null
  messageAttachmentUploadFolderId?: string
  downloadAssignmentSubmissionsUrl?: string
}

export type AssignmentDetailCalculationText = {
  max: string
  min: string
  pointsPossible: string
  average: string
  median: string
  lowerQuartile: string
  upperQuartile: string
}

export type SortableAssignment = AssignmentConnection & {
  assignmentGroupPosition: number
  sortableName: string
  sortableDueDate: number
  gradingPeriodId?: string | null
}

export type AssignmentSortContext = {
  sortType?: GradebookSortOrder
}

export type SortableStudent = UserConnection & {
  sections: string[]
  hiddenName?: string
  state: string
  sortableName: string
}

export enum ApiCallStatus {
  NOT_STARTED = 'NOT_STARTED',
  NO_CHANGE = 'NO_CHANGE',
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

export type AssignmentSubmissionsMap = {
  [assignmentId: string]: {
    [submissionId: string]: SubmissionConnection
  }
}

export type AssignmentGradingPeriodMap = Record<string, string | null | undefined>

export type SubmissionGradeChange = Pick<
  GradebookUserSubmissionDetails,
  | 'id'
  | 'assignmentId'
  | 'score'
  | 'enteredScore'
  | 'missing'
  | 'excused'
  | 'late'
  | 'grade'
  | 'state'
  | 'submittedAt'
  | 'userId'
>
