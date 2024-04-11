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

import {z} from 'zod'
import type {
  Assignment,
  AssignmentGroup,
  Enrollment,
  GradingType,
  LatePolicyStatus,
  Submission,
  SubmissionType,
  WorkflowState,
} from '../../api.d'
import {GradingStandard} from '@instructure/grading-utils'

export type OriginalityData = {
  reportUrl: string
  score: number
  status: string
  state: string
}

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
  currentScore?: string
}

// TODO: remove the need for this type
export type CamelizedStudent = {
  avatarUrl: string
  displayName: string
  enrollments: Enrollment[]
  id: string
  initialized: boolean
  isConcluded: boolean
  loaded: boolean
  name: string
  sortableName: string
  totalGrade: number
}

export type SubmissionData = {
  id?: string
  dropped: boolean | undefined
  enteredGrade?: string | null
  enteredScore?: number | null
  excused: boolean
  extended: boolean
  grade: string | null
  late: boolean
  missing: boolean
  pointsDeducted?: number | null
  resubmitted: boolean
  score: number | null
  customGradeStatusId?: string | null
}

// TODO: remove the need for this
export type CamelizedSubmission = {
  anonymousId: string
  assignmentId: string
  assignmentVisible?: boolean
  attempt: number | null
  cachedDueDate: null | string
  customGradeStatusId?: null | string
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
  closeDate: Date
  endDate: Date
  id: string
  isClosed: boolean
  isLast: boolean
  startDate: Date
  title: string
  weight: number
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

export type SerializedGradingPeriod = {
  close_date: string
  end_date: string
  id: string
  is_closed?: boolean
  is_last?: boolean | string
  start_date: string
  title: string
  weight: number
}

export type CamelizedAssignment = {
  allowedAttempts: number
  anonymousGrading: boolean
  anonymizeStudents: boolean
  courseId: string
  dueAt: string | null
  gradesPublished: boolean
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
  submissionTypes: string[]
}

export const ZSubmissionOriginalityData = z
  .object({
    error_message: z.string().optional(),
    status: z.string().optional(),
    provider: z.string().optional(),
    similarity_score: z.number().optional(),
    state: z.string().optional(),
    public_error_message: z.string().optional(),
    report_url: z.string().optional(),
  })
  .extend(z.record(z.unknown()).shape) // TODO: expand

export type SubmissionOriginalityData = z.infer<typeof ZSubmissionOriginalityData>

export const ZVericiteOriginalityData = ZSubmissionOriginalityData.extend(
  z.object({
    provider: z.literal('vericite'),
  }).shape
)

export type VericiteOriginalityData = z.infer<typeof ZVericiteOriginalityData>

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

export type CamelizedSubmissionWithOriginalityReport = CamelizedSubmission & {
  attachments: Array<{id: string}>
  hasOriginalityReport: boolean
  turnitinData?: SubmissionOriginalityDataMap
  vericiteData?: {provider: 'vericite'} & SubmissionOriginalityDataMap
}

export type FinalGradeOverride = {
  courseGrade?: {
    percentage?: number | null
    schemeKey?: string | null
    customGradeStatusId?: string | null
  }
  gradingPeriodGrades?: {
    [gradingPeriodId: string]: {
      percentage?: number | null
      schemeKey?: string | null
      customGradeStatusId?: string | null
    }
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
  excused: boolean
  grade: null | string
  late_policy_status: null | LatePolicyStatus
  score: null | number
  valid: boolean
}

export type AssignmentGroupGradeMap = {
  [assignmentGroupId: string]: AssignmentGroupGrade
}

export type StudentGrade = {
  score: number
  possible: number
  submission: Submission
  drop?: boolean
}

export type AggregateGrade = {
  score: number
  possible: number
  submission_count: number
  submissions: StudentGrade[]
}

export type AssignmentGroupGrade = {
  assignmentGroupId: string
  assignmentGroupWeight: number
  current: AggregateGrade
  final: AggregateGrade
  scoreUnit: 'points' | 'percentage'
}

export type GradingPeriodGrade = {
  gradingPeriodId: string
  gradingPeriodWeight: number
  assignmentGroups: AssignmentGroupGradeMap
  scoreUnit: 'points' | 'percentage'
  final: {
    score: number
    possible: number
    submission_count?: number
    submissions?: Submission[]
  }
  current: {
    score: number
    possible: number
    submission_count?: number
    submissions?: Submission[]
  }
}

export type GradingPeriodGradeMap = {
  [gradingPeriodId: string]: GradingPeriodGrade
}

export type FormatGradeOptions = {
  formatType?: 'points_out_of_fraction'
  defaultValue?: string
  gradingType?: string
  delocalize?: boolean
  precision?: number
  pointsPossible?: number
  score?: number | null
  restrict_quantitative_data?: boolean
  grading_scheme?: DeprecatedGradingScheme[]
}

/**
 * @deprecated
 */
export type DeprecatedGradingScheme = {
  id?: string
  title?: string
  pointsBased: boolean
  scalingFactor: number
  data: GradingStandard[]
}

export type GradeEntryOptions = {
  gradingScheme?: {data: GradingStandard[]; pointsBased: boolean; scalingFactor: number} | null
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

export type AssignmentGradeCriteria = Pick<
  Assignment,
  | 'id'
  | 'points_possible'
  | 'submission_types'
  | 'anonymize_students'
  | 'omit_from_final_grade'
  | 'workflow_state'
>
export type SubmissionGradeCriteria = Pick<
  Submission,
  'score' | 'grade' | 'assignment_id' | 'workflow_state' | 'excused' | 'id'
>

export type AssignmentGroupCriteriaMap = {
  [id: string]: Omit<AssignmentGroup, 'assignments'> & {
    assignments: AssignmentGradeCriteria[]
    invalid?: boolean
    gradingPeriodsIds?: string[]
  }
}

export type Progress = {
  id: string
  workflow_state: string
  message?: string
  updated_at?: string
}

export type ProgressData = {
  progress: Progress
}
