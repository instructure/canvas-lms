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

export type CourseSettingsType = {
  filter_speed_grader_by_student_group: boolean
  allow_final_grade_override: boolean
}

export type GradebookSettings = {
  hide_assignment_group_totals: string
  show_separate_first_last_names: string
  show_unpublished_assignments: string
  show_concluded_enrollments: string
  show_inactive_enrollments: string
  hide_assignment_group_totals: string
  hide_total: string
}

export type GradebookOptions = {
  active_grading_periods: GradingPeriod[]
  allow_apply_score_to_ungraded: boolean
  allow_separate_first_last_names: boolean
  allow_view_ungraded_as_zero: boolean
  applyScoreToUngradedModalNode: HTMLElement
  attachment_url: string
  attachment: AttachmentData
  change_gradebook_version_url: string
  colors: StatusColors
  context_allows_gradebook_uploads: boolean
  context_code: string
  context_id: string
  context_sis_id: string | null
  context_url: string
  course_is_concluded: boolean
  course_name: string
  course_settings: CourseSettingsType
  course_url: string
  current_grading_period_id: string
  currentUserId: string
  custom_column_datum_url: string
  default_grading_standard: string
  download_assignment_submissions_url: string
  enhanced_gradebook_filters: boolean
  export_gradebook_csv_url: string
  filterNavNode: HTMLElement
  grade_calc_ignore_unposted_anonymous_enabled: boolean
  gradebook_column_order_settings_url: string
  gradebook_column_order_settings: ColumnOrderSettings
  gradebook_column_size_settings_url: string
  gradebook_column_size_settings: ColumnSizeSettings
  gradebook_csv_progress: ProgressData
  gradebook_import_url: string
  gradebook_score_to_ungraded_progress: ProgressData
  gradebook_is_editable: boolean
  gradebook_score_to_ungraded_progress: ProgressData
  graded_late_submissions_exist: boolean
  grading_period_set: GradingPeriodSet
  grading_standard: boolean
  group_weighting_scheme: string
  load_assignments_by_grading_period_enabled: boolean
  locale: string
  outcome_gradebook_enabled: boolean
  post_grades_feature: string
  post_grades_ltis: Lti[]
  publish_to_sis_enabled: boolean
  publish_to_sis_url: string
  re_upload_submissions_url: string
  reorder_custom_columns_url: string
  sections: Section[]
  setting_update_url: string
  settings_update_url: string
  settings: GradebookSettings
  show_concluded_enrollments: string
  show_inactive_enrollments: string
  show_similarity_score: boolean
  show_total_grade_as_points: boolean
  sis_name: string
  speed_grader_enabled: boolean
  student_groups: StudentGroupCategoryMap
  user_asset_string: string
}

export type Course = {
  id: string
}

export type Enrollment = {
  course_section_id: string
  type: string
  grades: {
    html_url: string
  }
}

export type Student = {
  id: string
  name: string
  displayName: string
  sortable_name: string
  avatar_url: string
  enrollments: Enrollment[]
  loaded: boolean
  initialized: boolean
  isConcluded: boolean
  total_grade: number
} & {
  // computed values
  computed_current_score: number
  computed_final_score: number
  isInactive: boolean
  cssClass: string
  sections: string[]
}

export type StudentMap = {
  [key: string]: Student
}

export type StudentGroup = Partial<
  {
    avatar_url: null | string
    concluded: boolean
    context_type: string
    course_id: string
    created_at: string
    description: null | string
    group_category_id: string
    has_submission: boolean
    id: string
    is_public: boolean
    join_level: string
    leader: null | string
    max_membership: null | string
    members_count: string
    name: string
    role: null | string
    sis_group_id: null | string
    sis_import_id: null | string
    storage_quota_mb: string
  },
  'id' | 'name'
>

export type StudentGroupMap = {
  [key: string]: StudentGroup
}

export type StudentGroupCategory = Partial<
  {
    allows_multiple_memberships: boolean
    auto_leader: null | string
    context_type: string
    course_id: string
    created_at: string
    group_limit: null
    groups: StudentGroup[]
    id: string
    is_member: boolean
    name: string
    protected: boolean
    role: null | string
    self_signup: null | string
    sis_group_category_id: null | string
    sis_import_id: null | string
  },
  'id' | 'name' | 'groups'
>

export type StudentGroupCategoryMap = {
  [key: string]: StudentGroupCategory
}

export type Assignment = {
  id: string
  name: string
  assignment_id: string
  user_id: string
  hidden: boolean
  anonymize_students: boolean
  published: boolean
  submission_types: string
  assignment_group_id: string
  module_ids: string[]
  effectiveDueDates: EffectiveDueDateUserMap
  inClosedGradingPeriod: boolean
  grading_type: string
  points_possible: number
  omit_from_final_grade: boolean
  only_visible_to_overrides: boolean
  assignment_visibility: string[]
  grading_standard_id: string | null
  hasDownloadedSubmissions: boolean
  overrides: any
}

export type AssignmentMap = {
  [key: string]: Assignment
}

export type AssignmentGroup = {
  id: string
  name: string
  position: number
  group_weight: number
  assignments: Assignment[]
}

export type AssignmentGroupMap = {
  [key: string]: AssignmentGroup
}

export type Submission = {
  attempt: number | null
  user_id: string
  assignment_id: string
  submitted_at: string
  gradingType: string
  excused: boolean
  hidden: boolean
  rawGrade: string | null
  grade: string | null
  posted_at: string
  assignment_visible: boolean
}

export type SubmissionCommentData = {
  group_comment: 1 | 0
  text_comment: string
  attempt?: number
}

export type UserSubmissionGroup = {
  user_id: string
  submissions: Submission[]
}

export type CourseContent = {
  contextModules: any[]
  courseGradingScheme: {
    data: any
  } | null
  defaultGradingScheme: {
    data: any
  } | null
  gradingSchemes: any
  gradingPeriodAssignments: any
  assignmentStudentVisibility: {[key: string]: null | boolean}
  latePolicy: any
  students: StudentDatastore
  modulesById: any
}

export type ContentLoadStates = {
  assignmentGroupsLoaded: boolean
  contextModulesLoaded: boolean
  assignmentsLoaded: {
    all: boolean
    gradingPeriod: any
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
  valid: boolean
}

export type InitialActionStates = {
  pendingGradeInfo: PendingGradeInfo[]
}

export type FlashAlertType = {
  key: string
  message: string
  variant: string
}

export type Module = {
  id: string
  name: string
  position: number
}

export type Section = {
  id: string
  name: string
}

export type SectionMap = {
  [key: string]: Section
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

export type AssignmentDueDate = {
  due_at: string
  grading_period_id: string | null
  in_closed_grading_period: boolean
}

export type EffectiveDueDateUserMap = {
  [user_id: string]: AssignmentDueDate
}

export type EffectiveDueDateAssignmentUserMap = {
  [assignment_id: string]: EffectiveDueDateUserMap
}

export type GradingPeriod = {
  id: string
  title: string
  startDate: number
}

export type GradingPeriodSet = {
  gradingPeriods: GradingPeriod[]
  displayTotalsForAllGradingPeriods: boolean
  weighted: any
}

export type ColumnSizeSettings = {
  [key: string]: string
}

export type AttachmentData = {
  attachment: Attachment
}

export type Attachment = {
  id: string
  updated_at: string
  created_at: string
}

export type Lti = {
  id: string
  name: string
  data_url: string
}

export type ColumnOrderSettings = {
  freezeTotalGrade: any
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
