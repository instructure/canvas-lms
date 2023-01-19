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
  [id: string]: Student
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

export type StudentGroupCategory = {
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
}

export type StudentGroupMap = {
  [id: string]: StudentGroup
}

export type StudentGroupCategoryMap = {
  [id: string]: StudentGroupCategory
}

export type DueDate = {
  due_at: string | null
  grading_period_id: string | null
  in_closed_grading_period: boolean
}

export type UserDueDateMap = {
  [user_id: string]: DueDate
}

export type AssignmentUserDueDateMap = {
  [assignment_id: string]: UserDueDateMap
}

export type Override = {
  title: string
  id: string
  due_at: string | null
  course_section_id: string | null
}

export type Assignment = {
  allowed_attmpts: number
  allowed_extensions: string[]
  annotatable_attachment_id: null | string
  anonymize_students: boolean
  anonymous_grading: boolean
  anonymous_instructor_annotations: boolean
  anonymous_peer_reviews: boolean
  assessment_requests: AssessmentRequest[]
  assignment_group_id: string
  assignment_group: AssignmentGroup // assigned after fetch?
  assignment_id: string
  assignment_visibility: string[]
  automatic_peer_reviews: boolean
  can_duplicate: boolean
  course_id: string
  created_at: string
  due_at: string | null
  due_date_required: boolean
  effectiveDueDates: UserDueDateMap
  final_grader_id: null | string
  grade_group_students_individually: boolean
  graded_submissions_exist: boolean
  grader_comments_visible_to_graders: boolean
  grader_count: number
  grader_names_visible_to_final_grader: boolean
  graders_anonymous_to_graders: boolean
  grades_published: boolean
  grading_standard_id: string | null
  grading_type: string
  group_category_id: string | null
  has_overrides: boolean
  has_submitted_submissions: boolean
  html_url: string
  id: string
  important_dates: boolean
  in_quiz_assignment: boolean
  inClosedGradingPeriod: boolean
  integration_data: any
  integration_id: string
  intra_group_peer_reviews: boolean
  lock_at: null | string
  locked_for_user: boolean
  lti_context_id: string
  max_name_length: number
  moderated_grading: boolean
  module_ids: string[]
  module_positions: number[]
  muted: boolean
  name: string
  omit_from_final_grade: boolean
  only_visible_to_overrides: boolean
  original_assignment_id: null | string
  original_assignment_name: null | string
  original_course_id: null | string
  original_lti_resource_link_id: null | string
  original_quiz_id: null | string
  overrides: Override[]
  peer_reviews: boolean
  points_possible: number
  position: number
  post_manually: boolean
  post_to_sis: boolean
  published: boolean
  require_lockdown_browser: boolean
  secure_params: string
  sis_assignment_id: null | string
  submission_types: string[]
  submissions_download_url: string
  unlock_at: null | string
  unpublishable: boolean
  updated_at: string
  user_id: string
  workflow_state: WorkflowState
}

export type AssignmentMap = {
  [id: string]: Assignment
}

export type AssignmentGroup = {
  assignments: Assignment[]
  group_weight: number
  id: string
  integration_data: unknown
  name: string
  position: number
  rules: unknown
  sis_source_id: null | string
}

export type AssignmentGroupMap = {
  [id: string]: AssignmentGroup
}

export type AssessmentRequest = {
  anonymous_id?: string
  user_id?: string
  user_name?: string
  available: boolean
}

export type AttachmentData = {
  attachment: Attachment
}

export type Attachment = {
  id: string
  updated_at: string
  created_at: string
}

export type Module = {
  id: string
  name: string
  position: number
}

export type ModuleMap = {
  [id: string]: Module
}

export type Section = {
  course_id: string
  created_at: string
  end_at: null | string
  id: string
  integration_id: null | string
  name: string
  nonxlist_course_id: null | string
  restrict_enrollments_to_section_dates: null | boolean
  sis_course_id: null | string
  sis_import_id: null | string
  sis_section_id: null | string
  start_at: null | string
}

export type SectionMap = {
  [id: string]: Section
}

export type GradingType =
  | 'points'
  | 'percent'
  | 'letter_grade'
  | 'gpa_scale'
  | 'pass_fail'
  | 'not_graded'

export type SubmissionType =
  | null
  | 'basic_lti_launch'
  | 'discussion_topic'
  | 'external_tool'
  | 'media_recording'
  | 'on_paper'
  | 'online_quiz'
  | 'online_text_entry'
  | 'online_upload'
  | 'online_url'
  | 'wiki_page'

export type WorkflowState =
  | 'assigned'
  | 'complete'
  | 'deleted'
  | 'graded'
  | 'not_graded'
  | 'settings_only'
  | 'pending_review'
  | 'submitted'
  | 'unsubmitted'
  | 'untaken'

export type Submission = {
  anonymous_id: string
  assignment_id: string
  assignment_visible?: boolean
  attempt: number | null
  cached_due_date: null | string
  drop?: boolean
  entered_grade: null | string
  entered_score: null | number
  excused: boolean
  grade_matches_current_submission: boolean
  grade: string | null
  gradeLocked: boolean
  grading_period_id: string
  gradingType: GradingType
  has_postable_comments: boolean
  has_originality_report: boolean
  hidden: boolean
  id: string
  late_policy_status: null | string
  late: boolean
  missing: boolean
  points_deducted: null | number
  posted_at: null | Date
  rawGrade: string | null
  redo_request: boolean
  score: null | number
  seconds_late: number
  submission_type: SubmissionType
  submitted_at: null | Date
  url: null | string
  user_id: string
  workflow_state: WorkflowState
}

export type UserSubmissionGroup = {
  user_id: string
  submissions: Submission[]
}

export type SubmissionComment = {
  id: string
  created_at: string
  comment: string
  edited_at: null | string
  updated_at: string
  display_updated_at?: string
  is_read?: boolean
  author?: {
    id: string
    display_name: string
    avatar_image_url: string
    html_url: string
  }
}

export type SubmissionCommentData = {
  group_comment: 1 | 0
  text_comment: string
  attempt?: number
}

export type GradingPeriod = {
  close_date: string
  end_date: string
  id: string
  is_closed: boolean
  is_last: boolean
  permission: {
    read: boolean
    update: boolean
    create: boolean
    delete: boolean
  }
  start_date: string
  title: string
  weight: null | number
}

export type SubmissionAttemptsComments = {
  attempts: {
    [key: string]: SubmissionComment[]
  }
}

export type GradingPeriodSet = {
  account_id: string
  course_id: null | string
  created_at: string
  display_totals_for_all_grading_periods: boolean
  grading_periods: GradingPeriod[]
  id: string
  root_account_id: string
  title: string
  updated_at: string
  weighted: boolean
  workflow_state: WorkflowState
}
