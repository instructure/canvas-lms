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

import StudentDatastore from './stores/StudentDatastore'
import type {StatusColors} from './constants/colors'
import type {
  AssignmentGroup,
  AttachmentData,
  GradingPeriod,
  GradingPeriodSet,
  GradingType,
  Module,
  ModuleMap,
  Section,
  Student,
  StudentGroupCategoryMap,
  StudentMap,
  SubmissionType,
  WorkflowState,
} from '../api.d'

export type CourseSettingsType = {
  filter_speed_grader_by_student_group: boolean
  allow_final_grade_override: boolean
}

export type GradebookSettings = {
  enter_grades_as: any
  filter_columns_by: {
    assignment_group_id: string | null
    grading_period_id: string | null
    context_module_id: string | null
    end_date: string | null
    start_date: string | null
    submissions: 'has-ungraded-submissions' | 'has-submissions' | null
  }
  filter_rows_by: {
    section_id: string | null
    student_group_id: string | null
  }
  hide_assignment_group_totals: 'false' | 'true'
  hide_total: 'false' | 'true'
  selected_view_options_filters: string[]
  show_concluded_enrollments: 'false' | 'true'
  show_inactive_enrollments: 'false' | 'true'
  show_separate_first_last_names: 'false' | 'true'
  show_unpublished_assignments: 'false' | 'true'
  sort_rows_by_column_id: string
  sort_rows_by_direction: 'ascending' | 'descending'
  sort_rows_by_setting_key: string
  student_column_display_as: 'last_first' | 'first_last'
  student_column_secondary_info: string
  view_ungraded_as_zero: 'false' | 'true'
  colors?: StatusColors
}

export type PerformanceControlValues = {
  activeRequestLimit?: number
  apiMaxPerPage?: number
  assignmentGroupsPerPage?: number
  contextModulesPerPage?: number
  customColumnDataPerPage?: number
  customColumnsPerPage?: number
  studentsChunkSize?: number
  submissionsChunkSize?: number
  submissionsPerPage?: number
}

export type GradebookOptions = {
  active_grading_periods: GradingPeriod[]
  allow_apply_score_to_ungraded: boolean
  allow_separate_first_last_names: boolean
  allow_view_ungraded_as_zero: boolean
  assignment_missing_shortcut: boolean
  attachment_url: null | string
  attachment: null | AttachmentData
  change_gradebook_version_url: string
  colors: StatusColors
  context_allows_gradebook_uploads: boolean
  context_code: string
  context_id: string
  context_sis_id: null | string
  context_url: string
  course_is_concluded: boolean
  course_name: string
  course_settings: CourseSettingsType
  course_url: string
  current_grading_period_id: string
  custom_column_datum_url: string
  default_grading_standard: GradingStandard[]
  download_assignment_submissions_url: string
  enhanced_gradebook_filters: boolean
  enrollments_url: string
  enrollments_with_concluded_url: string
  export_gradebook_csv_url: string
  final_grade_override_enabled: boolean
  grade_calc_ignore_unposted_anonymous_enabled: boolean
  grade_calc_ignore_unposted_anonymous_enabled: boolean
  gradebook_column_order_settings_url: string
  gradebook_column_order_settings: ColumnOrderSettings
  gradebook_column_size_settings_url: string
  gradebook_column_size_settings: ColumnSizeSettings
  gradebook_csv_progress: null | ProgressData
  gradebook_import_url: string
  gradebook_is_editable: boolean
  gradebook_score_to_ungraded_progress: null | ProgressData
  graded_late_submissions_exist: boolean
  grading_period_set: GradingPeriodSet
  grading_schemes: GradingScheme[]
  grading_standard: boolean
  group_weighting_scheme: null | string
  has_modules: boolean
  late_policy: LatePolicy | null
  login_handle_name: null | string
  message_attachment_upload_folder_id: string
  new_gradebook_development_enabled: boolean
  outcome_gradebook_enabled: boolean
  performance_controls: PerformanceControlValues
  post_grades_feature: boolean
  post_grades_ltis: Lti[]
  post_manually: boolean
  publish_to_sis_enabled: boolean
  publish_to_sis_url: string
  re_upload_submissions_url: string
  reorder_custom_columns_url: string
  sections: Section[]
  setting_update_url: string
  settings_update_url: string
  settings: GradebookSettings
  show_message_students_with_observers_dialog: boolean
  show_message_students_with_observers_dialog: boolean
  show_similarity_score: boolean
  show_total_grade_as_points: boolean
  sis_app_token: null | string
  sis_app_url: null | string
  sis_name: null | string
  sis_name: string
  speed_grader_enabled: boolean
  student_groups: StudentGroupCategoryMap
  user_asset_string: string
  teacher_notes: {
    hidden: boolean
    id: string
    position: number
    read_only: boolean
    teacher_notes: boolean
    title: string
  }
  version: null | string
}

export type GradingStandard = [string, number]

export type GradingScheme = {
  id?: string
  title?: string
  data: GradingStandard[]
}

export type LatePolicy = {
  missing_submission_deduction_enabled: boolean
  missing_submission_deduction: number
}

// TODO: remove the need for this type
export type LatePolicyCamelized = {
  missingSubmissionDeductionEnabled: boolean
  missingSubmissionDeduction: number
  lateSubmissionInterval: string
}

export type GradingPeriodAssignmentMap = {
  [gradingPeriodId: string]: string[]
}

export type CourseContent = {
  contextModules: Module[]
  courseGradingScheme: {data: boolean} | null
  defaultGradingScheme: GradingScheme | null
  gradingSchemes: GradingScheme[]
  gradingPeriodAssignments: GradingPeriodAssignmentMap
  assignmentStudentVisibility: {[assignmentId: string]: null | StudentMap}
  latePolicy: LatePolicyCamelized
  students: StudentDatastore
  modulesById: ModuleMap
}

export type ContentLoadStates = {
  assignmentGroupsLoaded: boolean
  contextModulesLoaded: boolean
  assignmentsLoaded: {
    all: boolean
    gradingPeriod: {
      [gradingPeriodId: string]: boolean
    }
  }
  customColumnsLoaded: boolean
  gradingPeriodAssignmentsLoaded: boolean
  overridesColumnUpdating: boolean
  studentIdsLoaded: boolean
  studentsLoaded: boolean
  submissionsLoaded: boolean
  teacherNotesColumnUpdating: boolean
}

export type PendingGradeInfo = {
  userId: string
  assignmentId: string
  excused: boolean
  valid: boolean
  grade?: string
}

export type InitialActionStates = {
  pendingGradeInfo: PendingGradeInfo[]
}

export type FlashAlertType = {
  key: string
  message: string
  variant: string
}

export type FilterType =
  | 'section'
  | 'module'
  | 'assignment-group'
  | 'grading-period'
  | 'student-group'
  | 'start-date'
  | 'end-date'
  | 'submissions'

export type Filter = {
  id: string
  type?: FilterType
  value?: string
  created_at: string
}

export type SubmissionFilterValue = 'has-ungraded-submissions' | 'has-submissions' | undefined

export type FilterPreset = {
  id: string
  name: string
  filters: Filter[]
  created_at: string
  updated_at: string
}

export type PartialFilterPreset = Omit<FilterPreset, 'id'> & {id?: string}

export type FilterDrilldownData = {
  [key: string]: FilterDrilldownMenuItem
}

export type FilterDrilldownMenuItem = {
  id: string
  parentId?: null | string
  name: string
  isSelected?: boolean
  onToggle?: () => void
  items?: FilterDrilldownMenuItem[]
  itemGroups?: FilterDrilldownMenuItem[]
}

export type GradebookFilterApiRequest = {
  name: string
  payload: {
    conditions: Filter[]
  }
}

export type GradebookFilterApiResponse = {
  gradebook_filter: GradebookFilterApiResponseFilter
}

export type GradebookFilterApiResponseFilter = {
  course_id: string
  id: string
  user_id: string
  name: string
  payload: {
    conditions: Filter[]
  }
  created_at: string
  updated_at: string
}

export type ColumnSizeSettings = {
  [key: string]: string
}

export type Lti = {
  id: string
  name: string
  data_url: string
}

export type ColumnOrderSettings = {
  customOrder?: string[]
  direction: 'ascending' | 'descending'
  freezeTotalGrade?: boolean | 'true'
  sortType: string
}

export type Progress = {
  id: string
  workflow_state: string
}

export type ProgressData = {
  progress: Progress
}

export type FilteredContentInfo = {
  invalidAssignmentGroups: AssignmentGroup[]
  totalPointsPossible: number
}

export type FlashMessage = {
  key: string
  message: string
  variant: string
}

// TODO: remove the need for this type
export type SubmissionCamelized = {
  anonymousId: string
  assignmentId: string
  assignmentVisible?: boolean
  attempt: number | null
  enteredGrade: string | null
  enteredScore: number | null
  excused: boolean
  grade: string | null
  gradeMatchesCurrentSubmission: boolean
  cachedDueDate: string | null
  drop?: boolean
  gradeLocked: boolean
  gradingPeriodId: string | null
  gradingType: GradingType
  hasPostableComments: boolean
  hidden: boolean
  id: string
  latePolicyStatus: null | string
  late: boolean
  missing: boolean
  pointsDeducted: number | null
  postedAt: string | null
  rawGrade: string | null
  redoRequest: boolean
  score: null | number
  secondsLate: number | null
  submissionType: SubmissionType
  submittedAt: null | Date
  url: null | string
  userId: string
  workflowState: WorkflowState
}

export type AssignmentStudentMap = {
  [assignmentId: string]: StudentMap
}

export type StudentGrade = {
  score: number
  possible: number
  submissions: any
}

// TODO: store student grades in separate map so that the
//   student object isn't rendered "any"
export type GradebookStudent = Student & {
  [assignmentGroupGradeKey: `assignment_group_${string}`]: StudentGrade
} & {
  [assignmentGradeKey: `assignment_${string}`]: StudentGrade
} & {
  [columnGradeKey: `custom_col_${string}`]: any
}

export type GradebookStudentMap = {
  [studentId: string]: GradebookStudent
}

export type CustomColumn = {
  hidden: boolean
  id: string
  position: number
  read_only: boolean
  teacher_notes: boolean
  title: string
}

export type CustomColumnData = {
  user_id: string
  content: unknown
}

export type SerializedComment = {
  id: string
  comment: string
  createdAt: Date
  editedAt: null | Date
  authorId?: string
  author?: string
  authorAvatarUrl?: string
  authorUrl?: string
}

export type AssignmentWithOverride = {
  id: string
  name: string
  due_at: string
  please_ignore: boolean
  hadOriginalErrors: boolean
  overrideForThisSection: {
    id: string
    course_section_id: string
    due_at: null | Date
  }
}
