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
  LatePolicyStatus,
  Override,
  Submission,
  SubmissionType,
  UserDueDateMap,
  WorkflowState,
} from '../../api.d'

export type PartialStudent = {
  id: string
  isInactive: boolean
  isTestStudent: boolean
  name: string
  sortableName: string
  submission: {
    excused: boolean
    grade: null | string
    hasPostableComments: boolean
    latePolicyStatus: null | string
    redoRequest: boolean
    postedAt: null | Date
    score: null | number
    submittedAt: null | Date
    workflowState: WorkflowState
  }
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
export type SubmissionCommentCamelized = {
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
export type SubmissionCamelized = {
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
  proxySubmitter?: string
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

export type CamelizedGradingPeriod = {
  id: string
  title: string
  startDate: Date
  endDate: Date
  isClosed: boolean
}

export type CamelizedGradingPeriodSet = {
  createdAt: Date
  displayTotalsForAllGradingPeriods: boolean
  enrollmentTermIDs?: string[]
  gradingPeriods: CamelizedGradingPeriod[]
  id: string
  isClosed?: boolean
  permissions: unknown
  title: string
  weighted: boolean
}

export type CamelizedAssignment = {
  allowedAttempts: number
  anonymizeStudents: boolean
  courseId: string
  dueAt: string | null
  gradingType: GradingType
  groupSet?: {
    currentGroup: {
      _id: string
    }
  }
  htmlUrl: string
  id: string
  moderatedGrading: boolean
  muted: boolean
  name: string
  pointsPossible: number
  postManually: boolean
  published: boolean
  submissionTypes: string
}

export type SubmissionOriginalityData = {
  status: string
  provider: string
  similarity_score: number
  state?: string
  public_error_message?: string
  report_url?: string
}

export type SimilarityEntry = {
  id: string
  data: SubmissionOriginalityData
}

export type SubmissionWithOriginalityReport = Submission & {
  attachments: Array<{
    id: string
    attachment: {
      id: string
    }
  }>
  has_originality_report: boolean
  turnitin_data?: {
    [key: string]: SubmissionOriginalityData
  }
  vericite_data?: {provider: 'vericite'} & {
    [key: string]: SubmissionOriginalityData
  }
}

export type SubmissionOriginalityDataMap = {
  [key: string]: SubmissionOriginalityData
}

export type SimilarityType = 'vericite' | 'turnitin' | 'originality_report'

export type CamelizedSubmissionWithOriginalityReport = SubmissionCamelized & {
  attachments: Array<{id: string}>
  hasOriginalityReport: boolean
  turnitinData?: SubmissionOriginalityDataMap
  vericiteData?: {provider: 'vericite'} & SubmissionOriginalityDataMap
}

export type FinalGradeOverride = {
  courseGrade?: string
  gradingPeriodGrades?: {
    [gradingPeriodId: string]: string
  }
}

export type FinalGradeOverrideMap = {
  [userId: string]: FinalGradeOverride
}

export type GradeType = 'gradingScheme' | 'percent' | 'points' | 'passFail' | 'excused' | 'missing'

export type GradeEntryMode = 'gradingScheme' | 'passFail' | 'percent' | 'points'

export type GradeInput = {
  enteredAs: GradeType
  percent: null | number
  points: number
  schemeKey: null | string
}

export type GradeResult = {
  enteredAs: null | GradeType
  late_policy_status: null | LatePolicyStatus
  excused: boolean
  grade: null | string
  score: null | number
  valid: boolean
}

export type AssignmentGroupGrade = {
  assignmentGroupId: string
  assignmentGroupWeight: any
  current: {
    score: number
    possible: number
    submission_count: any
    submissions: any
  }
  final: {
    score: number
    possible: number
    submission_count: any
    submissions: any
  }
  scoreUnit: string
}

export type FormatGradeOptions = {
  formatType?: 'points_out_of_fraction'
  defaultValue?: string
  gradingType?: string
  delocalize?: boolean
  precision?: number
  pointsPossible?: number
}

export type GradingStandard = [string, number]

export type GradingScheme = {
  id?: string
  title?: string
  data: GradingStandard[]
}

export type ProvisionalGrade = {
  anonymous_grader_id?: string
  grade: string
  provisional_grade_id: string
  readonly: boolean
  scorer_id?: string
  scorer_name?: string
  selected?: boolean
  score: number | null
  rubric_assessments: RubricAssessment[]
}

export type RubricAssessment = {
  id: string
  assessor_id: string
  anonymous_assessor_id: string
  assessment_type: string
  assessor_name: string
}

export type SubmissionState =
  | 'not_gradeable'
  | 'not_graded'
  | 'graded'
  | 'resubmitted'
  | 'not_submitted'
