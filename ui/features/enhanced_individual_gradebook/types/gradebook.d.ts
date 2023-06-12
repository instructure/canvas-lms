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

import {AssignmentConnection, UserConnection} from './queries'
import {ProgressData} from 'features/gradebook/react/default_gradebook/gradebook'

export enum GradebookSortOrder {
  DueDate = 'dueDate',
  Alphabetical = 'alphabetical',
  AssignmentGroup = 'assignmentGroup',
}

export type GradebookOptions = {
  includeUngradedAssignments?: boolean
  anonymizeStudents?: boolean
  sortOrder: GradebookSortOrder
  selectedSection?: string
  exportGradebookCsvUrl?: string
  lastGeneratedCsvAttachmentUrl?: string | null
  gradebookCsvProgress?: ProgressData | null
  contextUrl?: string
  userId?: string
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
}

export type AssignmentSortContext = {
  sortType?: GradebookSortOrder
}

export type SortableStudent = UserConnection & {
  sections: string[]
}

export enum ApiCallStatus {
  NOT_STARTED = 'NOT_STARTED',
  NO_CHANGE = 'NO_CHANGE',
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}
