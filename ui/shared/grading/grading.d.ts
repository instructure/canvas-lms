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
  Enrollment,
  GradingType,
  Override,
  SubmissionType,
  UserDueDateMap,
  WorkflowState
} from '../../api.d'

export type PartialStudent = {
  id: string
  isInactive: boolean
  isTestStudent: boolean
  name: string
  sortableName: string
  submission: {
    excused: any
    grade: any
    hasPostableComments: any
    latePolicyStatus: any
    redoRequest: any
    postedAt: any
    score: any
    submittedAt: any
    workflowState: any
  }
}

export type SubmissionOriginalityData = {
  report_url: string
  similarity_score: number
  state: string
  status: string
}

export type OriginalityData = {
  reportUrl: string
  score: number
  status: string
  state: string
}

// TODO: remove the need for this type
export type CamelizedStudent = {
  id: string
  name: string
  displayName: string
  sortableName: string
  avatarUrl: string
  enrollments: Enrollment[]
  loaded: boolean
  initialized: boolean
  isConcluded: boolean
  totalGrade: number
}

// TODO: remove the need for this
export type CamelizedAssignment = {
  allowedAttempts: number
  anonymizeStudents: boolean
  anonymousGrading: boolean
  assignmentGroupId: string
  assignmentGroupPosition: number
  assignmentId: string
  assignmentVisibility: string[]
  courseId: string
  dueDate: string | null
  effectiveDueDates: UserDueDateMap
  gradesPublished: boolean
  gradingStandardId: string | null
  gradingType: GradingType
  hasDownloadedSubmissions: boolean
  hidden: boolean
  htmlUrl: string
  id: string
  inClosedGradingPeriod: boolean
  moderatedGrading: boolean
  moduleIds: string[]
  muted: boolean
  name: string
  omitFromFinalGrade: boolean
  onlyVisibleToOverrides: boolean
  overrides: Override[]
  pointsPossible: number
  position: number
  postManually: boolean
  published: boolean
  submissionTypes: string
  userId: string
}

// TODO: remove the need for this
export type CamelizedSubmission = {
  anonymousId: string
  assignmentId: string
  assignmentVisible?: boolean
  attempt: number | null
  cachedDueDate: null | string
  drop?: boolean
  enteredGrade: null | string
  enteredScore: null | number
  excused: boolean
  gradeMatchesCurrentSubmission: boolean
  grade?: string | null
  gradeLocked: boolean
  gradingPeriodId: string
  gradingType: GradingType
  hasPostableComments: boolean
  hidden: boolean
  id: string
  latePolicyStatus: null | string
  late: boolean
  missing: boolean
  pointsDeducted: null | number
  postedAt: null | Date
  rawGrade: string | null
  redoRequest: boolean
  score: null | number
  secondsLate: number
  submissionType: SubmissionType
  submittedAt: null | Date
  attachments: {
    id: string
    attachment: {
      id: string
    }
  }[]
  url: null | string
  userId: string
  workflowState: WorkflowState
}
