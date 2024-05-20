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

export type Enrollment = Readonly<{
  associated_user_id: null | string
  course_id: string
  course_integration_id: null | string
  course_section_id: string
  created_at: string
  end_at: null | string
  enrollment_state: 'active' | 'inactive' | 'completed' | 'invited'
  html_url: string
  id: string
  last_activity_at: null | string
  last_attended_at: null | string
  limit_privileges_to_course_section: boolean
  role_id: string
  root_account_id: string
  section_integration_id: null | string
  sis_account_id: null | string
  sis_course_id: null | string
  sis_import_id: null | string
  sis_section_id: null | string
  sis_user_id: null | string
  start_at: null | string
  total_activity_time: number
  type: 'StudentEnrollment' | 'StudentViewEnrollment'
  updated_at: string
  user_id: string
  grades: {
    html_url: string
    current_grade: null | number
    current_score: null | number
    final_grade: null | number
    final_score: null | number
    unposted_current_score: null | number
    unposted_current_grade: null | number
    unposted_final_score: null | number
    unposted_final_grade: null | number
  }
  workflow_state: WorkflowState
}>

export type Student = Readonly<{
  avatar_url?: string
  created_at: string
  email: null | string
  group_ids: string[]
  id: string
  integration_id: null | string
  login_id: string
  short_name: string
  sis_import_id: null | string
  sis_user_id: null | string
}> & {
  enrollments: Enrollment[]
  first_name: string
  last_name: string
  name: string
  index: number
  section_ids: string[]
} & Partial<{
    anonymous_name: string
    computed_current_score: number
    computed_final_score: number
    cssClass: string
    displayName: string
    initialized: boolean
    isConcluded: boolean
    isInactive: boolean
    loaded: boolean
    sections: string[]
    sortable_name: string
    total_grade: number
  }>

export type StudentMap = {
  [studentId: string]: Student
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

export type StudentGroupCategory = Readonly<{
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
}>

export type StudentGroupMap = {
  [id: string]: StudentGroup
}

export type StudentGroupCategoryMap = {
  [id: string]: StudentGroupCategory
}

export type DueDate = Readonly<{
  due_at: string | null
  grading_period_id: string | null
  in_closed_grading_period: boolean
}>

export type UserDueDateMap = {
  [user_id: string]: DueDate
}

export type AssignmentUserDueDateMap = {
  [assignment_id: string]: UserDueDateMap
}

export type Override = Readonly<{
  title: string
  id: string
  due_at: string | null
  course_section_id: string | null
}>

export type Assignment = Readonly<{
  allowed_attempts: number
  created_at: string
  id: string
  html_url: string
  allowed_extensions: string[]
  annotatable_attachment_id: null | string
  anonymous_grading: boolean
  anonymous_instructor_annotations: boolean
  anonymous_peer_reviews: boolean
  assessment_requests?: AssessmentRequest[]
  assignment_group_id: string
  automatic_peer_reviews: boolean
  can_duplicate: boolean
  course_id: string
  due_date_required: boolean
  final_grader_id: null | string
  grade_group_students_individually: boolean
  graded_submissions_exist: boolean
  grader_comments_visible_to_graders: boolean
  grader_count: number
  grader_names_visible_to_final_grader: boolean
  graders_anonymous_to_graders: boolean
  grades_published: boolean
  grading_standard_id: string | null
  grading_type: GradingType
  group_category_id: string | null
  has_overrides: boolean
  has_submitted_submissions: boolean
  hide_in_gradebook: boolean
  important_dates: boolean
  integration_data: any
  integration_id: null | string
  intra_group_peer_reviews: boolean
  is_quiz_assignment: boolean
  lock_at: null | string
  locked_for_user: boolean
  lti_context_id: string
  max_name_length: number
  moderated_grading: boolean
  module_ids?: string[]
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
  peer_reviews: boolean
  points_possible: number
  position: number
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
  workflow_state: WorkflowState
}> & {
  anonymize_students: boolean
  assignment_visibility: string[]
  post_manually: boolean
} & Partial<{
    assignment_group: AssignmentGroup
    due_at: string | null
    effectiveDueDates: UserDueDateMap
    inClosedGradingPeriod: boolean
    overrides: Override[]
  }>

export type AssignmentMap = {
  [assignmentId: string]: Assignment
}

export type AssignmentGroup = Readonly<{
  assignments: Assignment[]
  group_weight: number
  id: string
  integration_data: unknown
  name: string
  position: number
  rules: {
    drop_lowest?: number
    drop_highest?: number
    never_drop?: string[]
  }
  sis_source_id: null | string
}>

export type AssignmentGroupMap = {
  [id: string]: AssignmentGroup
}

export type AssessmentRequest = Readonly<{
  anonymous_id?: string
  user_id?: string
  user_name?: string
  available: boolean
  workflow_state?: string
}>

export type AssignedAssessments = {
  assetId: string
  workflowState: string
  assetSubmissionType: string | null
  anonymizedUser?: {
    displayName: string
    _id: string
  } | null
  anonymousId?: string | null
}

export type AttachmentData = Readonly<{
  attachment: Attachment
}>

export type Attachment = {
  canvadoc_url?: string
  comment_id?: string
  content_type: string
  created_at: string
  crocodoc_url?: string
  display_name: string
  filename: string
  hijack_crocodoc_session?: boolean
  id: string
  mime_class: string
  provisional_canvadoc_url?: null | string
  provisional_crocodoc_url?: null | string
  submitted_to_crocodoc?: boolean
  submitter_id: string
  updated_at: string
  upload_status: 'pending' | 'failed' | 'success'
  url?: string
  view_inline_ping_url?: string
  viewed_at: string
  word_count: number
  workflow_state: 'pending_upload' | 'processing'
}

export type Module = Readonly<{
  id: string
  name: string
  position: number
}>

export type ModuleMap = {
  [id: string]: Module
}

export type Section = Readonly<{
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
}>

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
  | 'completed'
  | 'deleted'
  | 'graded'
  | 'not_graded'
  | 'pending_review'
  | 'published'
  | 'settings_only'
  | 'submitted'
  | 'unpublished'
  | 'unsubmitted'
  | 'untaken'

export type SimilarityScore = {
  similarityScore: number
  status: 'error' | 'pending' | 'scored'
}

export type TurnitinAsset = {
  status: string
  provider: string
  similarity_score?: number
  state?: string
  public_error_message?: string
}

export type Submission = Readonly<{
  anonymous_id?: string
  assignment_id: string
  assignment_visible?: boolean
  attempt: number | null
  cached_due_date: null | string
  custom_grade_status_id: null | string
  drop?: boolean
  entered_grade: null | string
  entered_score: null | number
  grade_matches_current_submission: boolean
  gradeLocked: boolean
  grading_period_id: string
  grading_type: GradingType
  has_originality_report: boolean
  has_postable_comments: boolean
  id: string
  late_policy_status: null | LatePolicyStatus
  late: boolean
  missing: boolean
  points_deducted: null | string | number
  provisional_grade_id: string
  redo_request: boolean
  score: null | number
  seconds_late: number
  similarityInfo: null | SimilarityScore
  submission_type: SubmissionType
  url?: null | string
  user_id: string
  versioned_attachments?: any
  word_count: null | number
  workflow_state: WorkflowState
}> & {
  assignedAssessments?: AssignedAssessments[]
  attempt?: number
  excused: boolean
  external_tool_url?: string
  grade: string | null
  graded_at: string | null
  gradingType: GradingType
  has_originality_score?: any
  hidden: boolean
  posted_at: null | Date
  proxy_submitter?: string
  rawGrade: string | null
  submission_comments: SubmissionComment[]
  submitted_at: null | Date
  turnitin_data?: TurnitinAsset & {
    // TODO: refactor to separate out the dynamic object
    [key: string]: any
  }
  updated_at: string
  final_provisional_grade?: string
}

export type MissingSubmission = {
  assignment_id: string
  user_id: string
  excused: boolean
  late: boolean
  missing: boolean
  seconds_late: number
} & Partial<Submission>

export type AssignmentUserSubmissionMap = {
  [assignmentId: string]: {
    [userId: string]: Submission
  }
}

export type UserSubmissionGroup = {
  user_id: string
  section_id: string
  submissions: Submission[]
}
export type MediaTrack = {
  id: string
  locale: string
  content: string
  kind: string
  src?: string
  label?: string
  language?: string
  type?: string
}

export type MediaSource = {
  height: string
  url: string
  content_type: string
  width: string
  label?: string
  src?: string
}
export type MediaObject = {
  id: string
  media_type?: string
  title?: string
  media_sources: MediaSource[]
  media_tracks: MediaTrack[]
}

export type SubmissionComment = Readonly<{
  anonymous_id: string
  attachments: Attachment[]
  attempt?: number
  author_id: string
  avatar_path: string
  cached_attachments: Attachment[]
  comment: string
  created_at: string
  display_updated_at?: string
  draft: boolean
  edited_at: null | string
  group_comment_id: string
  id: string
  is_read?: boolean
  media_comment_id: string
  media_comment_type: string
  media_object?: MediaObject
  publishable: boolean
  submission_comment: SubmissionComment
  updated_at: string
  author?: {
    id: string
    display_name: string
    avatar_image_url: string
    html_url: string
  }
}> & {
  author_name: string
  posted_at: string
}

export type SubmissionCommentData = {
  group_comment: 1 | 0
  text_comment: string
  attempt?: number
}

export type GradingPeriod = Readonly<{
  close_date: string
  end_date: string
  id: string
  is_closed: boolean
  is_last: boolean
  permissions: {
    read: boolean
    update: boolean
    create: boolean
    delete: boolean
  }
  start_date: string
  title: string
  weight: number | null
}>

export type SubmissionAttemptsComments = {
  attempts: {
    [key: string]: SubmissionComment[]
  }
}

export type GradingPeriodSet = Readonly<{
  account_id: string
  course_id: string | null
  created_at: string
  display_totals_for_all_grading_periods: boolean
  enrollment_term_ids: string[]
  grading_periods: GradingPeriod[]
  id: string
  permissions: unknown
  root_account_id: string
  title: string
  updated_at: string
  weighted: boolean
  workflow_state: WorkflowState
}>

export type GradingPeriodSetGroup = {
  grading_period_sets: GradingPeriodSet[]
}

export type LatePolicyStatus = 'missing' | 'late' | 'extended'

// /api/v1/users/self/history
export type HistoryEntry = Readonly<{
  asset_code: string
  asset_name: string
  asset_icon: string
  asset_readable_category: string
  visited_url: string
  visited_at: string
  context_name: string
}>

// '/api/v1/accounts'
export type Account = Readonly<{
  id: string
  name: string
}>

// '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname',
export type Course = Readonly<{
  id: string
  name: string
  workflow_state: string
  enrollment_term_id: number
  term: {
    name: string
  }
  homeroom_course: boolean
}>

// '/api/v1/users/self/tabs',
type TabCountsObj = Readonly<{
  [key: string]: number | undefined
}>

export type ProfileTab = Readonly<{
  id: string
  label: string
  html_url: string
  counts: TabCountsObj
}>

// '/api/v1/users/self/groups?include[]=can_access',
export type AccessibleGroup = Readonly<{
  id: string
  name: string
  can_access?: boolean
  concluded: boolean
}>

// '/help_links',
export type HelpLink = Readonly<{
  id: string
  url: string
  text: string
  subtext?: string
  feature_headline?: string
  is_featured?: boolean
  is_new?: boolean
  no_new_window?: boolean
}>

// '/api/v1/release_notes/latest'
export type ReleaseNote = {
  id: string
  title: string
  description: string
  url: string
  date: string
  new: boolean
}
