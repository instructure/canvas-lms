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
  anonymous_grading: boolean
  anonymize_students: boolean
  anonymous_peer_reviews?: boolean
  assessment_requests: AssessmentRequest[]
  assignment_group_id: string
  assignment_group_position: number
  assignment_id: string
  assignment_visibility: string[]
  effectiveDueDates: UserDueDateMap
  grades_published: boolean
  grading_standard_id: string | null
  grading_type: string
  hasDownloadedSubmissions: boolean
  hidden: boolean
  id: string
  inClosedGradingPeriod: boolean
  moderated_grading: boolean
  module_ids: string[]
  name: string
  omit_from_final_grade: boolean
  only_visible_to_overrides: boolean
  overrides: Override[]
  points_possible: number
  position: number
  post_manually: boolean
  published: boolean
  submission_types: string
  user_id: string
}

export type AssignmentMap = {
  [id: string]: Assignment
}

export type AssignmentGroup = {
  id: string
  name: string
  position: number
  group_weight: number
  assignments: Assignment[]
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
  id: string
  name: string
}

export type SectionMap = {
  [id: string]: Section
}

export type GradingType = 'points' | 'percent' | 'letter_grade' | 'gpa_scale' | 'pass_fail'

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

export type SubmissionCommentData = {
  group_comment: 1 | 0
  text_comment: string
  attempt?: number
}

export type GradingPeriod = {
  id: string
  title: string
  startDate: Date
  endDate: Date
  isClosed: boolean
}

export type GradingPeriodSet = {
  gradingPeriods: GradingPeriod[]
  displayTotalsForAllGradingPeriods: boolean
  weighted: boolean
}
