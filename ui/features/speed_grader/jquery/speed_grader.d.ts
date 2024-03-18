/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import type JQuery from 'jquery'
import {ZSubmissionOriginalityData, ZVericiteOriginalityData} from '@canvas/grading/grading.d'
import type {SubmissionOriginalityData} from '@canvas/grading/grading.d'
import PostPolicies from '../react/PostPolicies/index'
import AssessmentAuditTray from '../react/AssessmentAuditTray'

// fields marked as z.null() can be improved in subsequent commits

export const ZSubmissionType = z.union([
  z.literal('basic_lti_launch'),
  z.literal('discussion_topic'),
  z.literal('media_recording'),
  z.literal('online_quiz'),
  z.literal('online_text_entry'),
  z.literal('online_upload'),
  z.literal('online_url'),
  z.literal('online'),
  z.literal('student_annotation'),
])

export type SubmissionType = z.infer<typeof ZSubmissionType>

export const ZAttachment = z.object({
  canvadoc_url: z.string().nullable(),
  comment_id: z.string().nullable(),
  content_type: z.string(),
  created_at: z.string(),
  crocodoc_url: z.string().nullable(),
  display_name: z.string(),
  filename: z.string(),
  hijack_crocodoc_session: z.boolean().nullable(),
  id: z.string(),
  mime_class: z.string(),
  provisional_canvadoc_url: z.string().nullable(),
  provisional_crocodoc_url: z.string().nullable(),
  submitted_to_crocodoc: z.boolean().nullable(),
  submitter_id: z.string(),
  updated_at: z.string(),
  upload_status: z.union([z.literal('pending'), z.literal('failed'), z.literal('success')]),
  url: z.string().nullable(),
  view_inline_ping_url: z.string().nullable(),
  viewed_at: z.string(),
  word_count: z.number(),
  workflow_state: z.union([z.literal('pending_upload'), z.literal('processing')]),
})

export type Attachment = z.infer<typeof ZAttachment>

export const ZVersionedAttachment = z.object({
  attachment: ZAttachment,
})

export type VersionedAttachment = z.infer<typeof ZVersionedAttachment>

export const ZRubricAssessment = z.object({
  id: z.string(),
  assessor_id: z.string(),
  anonymous_assessor_id: z.string(),
  assessment_type: z.string(),
  assessor_name: z.string().nullable(),
})

export type RubricAssessment = z.infer<typeof ZRubricAssessment>

export const ZProvisionalGrade = z.object({
  anonymous_grader_id: z.string().nullable(),
  grade: z.string().nullable(),
  provisional_grade_id: z.string(),
  readonly: z.boolean(),
  scorer_id: z.string().nullable(),
  scorer_name: z.string().nullable(),
  selected: z.boolean().nullable(),
  score: z.number().nullish(),
  rubric_assessments: z.array(ZRubricAssessment),
})

export type ProvisionalGrade = z.infer<typeof ZProvisionalGrade>

export const ZGradingType = z.union([
  z.literal('points'),
  z.literal('percent'),
  z.literal('letter_grade'),
  z.literal('gpa_scale'),
  z.literal('pass_fail'),
  z.literal('not_graded'),
])

export type GradingType = z.infer<typeof ZGradingType>

// lacks submission_history
const ZBaseSubmission = z.object({
  anonymous_id: z.string().optional(),
  assignment_id: z.string(),
  attachments: z.array(ZAttachment).optional(),
  attempt: z.number().nullable(),
  cached_due_date: z.string().nullish(),
  currentSelectedIndex: z.number().optional(), // added by SG
  custom_grade_status_id: z.string().nullable(),
  entered_grade: z.string().nullish(),
  entered_score: z.string().nullish(),
  excused: z.boolean().nullable(),
  external_tool_url: z.string().nullable(),
  final_provisional_grade: z
    .object({
      grade: z.string(),
    })
    .optional(),
  from_enrollment_type: z.string().optional(),
  grade_matches_current_submission: z.boolean().nullish(),
  grade: z.string().nullable(),
  graded_at: z.string().nullish(),
  grader_id: z.string().optional(),
  grading_period_id: z.string().nullable(),
  grading_type: ZGradingType.optional(),
  has_originality_report: z.boolean().optional(),
  has_originality_score: z.boolean().optional(),
  has_postable_comments: z.boolean().optional(),
  id: z.string(),
  late_policy_status: z.string().nullish(),
  late: z.boolean(),
  missing: z.boolean(),
  points_deducted: z.string().nullable(),
  posted_at: z.string().nullish(),
  provisional_grade_id: z.string().optional(),
  provisional_grades: z.array(ZProvisionalGrade).optional(),
  proxy_submitter_id: z.string().nullable(),
  proxy_submitter: z.boolean().nullish(),
  redo_request: z.boolean(),
  resource_link_lookup_uuid: z.string().nullish(),
  score: z.number().nullish(),
  seconds_late: z.number().optional(),
  show_grade_in_dropdown: z.boolean().optional(),
  submission_comments: z.lazy(() => z.array(ZSubmissionComment).optional()),
  submission_type: ZSubmissionType.nullable(),
  submitted_at: z.date().nullable(),
  turnitin_data: ZSubmissionOriginalityData.optional(),
  updated_at: z.string(),
  url: z.string().optional(),
  user_id: z.string(),
  vericite_data: ZVericiteOriginalityData.optional(), // not used in SpeedGrader
  version: z.number().optional(),
  word_count: z.null(),
  workflow_state: z.string(),
  versioned_attachments: z.array(ZVersionedAttachment).optional(),
})

export const ZHistoricalSubmission = ZBaseSubmission

export type HistoricalSubmission = z.infer<typeof ZHistoricalSubmission>

export const ZSubmissionHistoryEntry = z.object({
  assignment_id: z.string().optional(),
  attachments: z.array(ZAttachment).optional(),
  attempt: z.number().optional(),
  cached_due_date: z.string().nullish(),
  custom_grade_status_id: z.string().optional(),
  entered_grade: z.string().nullish(),
  entered_score: z.string().nullish(),
  excused: z.boolean().optional(),
  external_tool_url: z.string().optional(),
  from_enrollment_type: z.string().optional(),
  grade_matches_current_submission: z.boolean().nullish(),
  grade: z.string().optional(),
  graded_at: z.string().nullish(),
  grading_period_id: z.string().optional(),
  has_postable_comments: z.boolean().optional(),
  id: z.string().optional(),
  late_policy_status: z.string().nullish(),
  late: z.boolean().optional(),
  missing: z.boolean().optional(),
  points_deducted: z.string().optional(),
  posted_at: z.string().nullish(),
  proxy_submitter_id: z.string().optional(),
  proxy_submitter: z.boolean().nullish(),
  redo_request: z.boolean().optional(),
  resource_link_lookup_uuid: z.string().optional(),
  score: z.number().nullish(),
  seconds_late: z.number().optional(),
  submission: ZHistoricalSubmission,
})

export type SubmissionHistoryEntry = z.infer<typeof ZSubmissionHistoryEntry>

export const ZSubmission = ZBaseSubmission.extend({
  submission_history: z.array(ZSubmissionHistoryEntry),
})

export type Submission = z.infer<typeof ZSubmission>

export const ZStudent = z.object({
  avatar_url: z.string().nullable(),
  created_at: z.string(),
  email: z.string().nullable(),
  group_ids: z.array(z.string()),
  id: z.string(),
  integration_id: z.string().nullish(), // not used in SpeedGrader
  login_id: z.string().optional(), // not used in SpeedGrader
  name: z.string(),
  section_ids: z.array(z.string()),
  short_name: z.string(),
  sortable_name: z.string(),
  sis_import_id: z.string().nullish(), // not used in SpeedGrader
  sis_user_id: z.string().nullish(), // not used in SpeedGrader
})

export type Student = z.infer<typeof ZStudent>

export const ZWorkflowState = z.union([
  z.literal('assigned'),
  z.literal('completed'),
  z.literal('deleted'),
  z.literal('graded'),
  z.literal('not_graded'),
  z.literal('pending_review'),
  z.literal('published'),
  z.literal('settings_only'),
  z.literal('submitted'),
  z.literal('unpublished'),
  z.literal('unsubmitted'),
  z.literal('untaken'),
])

export type WorkflowState = z.infer<typeof ZWorkflowState>

export const ZAssignment = z.object({
  allowed_attempts: z.number(),
  created_at: z.string(),
  id: z.string(),
  html_url: z.string(), // not used in SpeedGrader
  allowed_extensions: z.array(z.string()), // not used in SpeedGrader
  annotatable_attachment_id: z.string().nullable(),
  anonymous_grading: z.boolean(),
  anonymous_instructor_annotations: z.boolean(),
  anonymous_peer_reviews: z.boolean(),
  assessment_requests: z.array(z.unknown()),
  assignment_group_id: z.string(),
  automatic_peer_reviews: z.boolean(), // not used in SpeedGrader
  can_duplicate: z.boolean(),
  course_id: z.string(),
  due_date_required: z.boolean(),
  final_grader_id: z.string().nullable(),
  grade_group_students_individually: z.boolean(), // not used in SpeedGrader
  graded_submissions_exist: z.boolean(),
  grader_comments_visible_to_graders: z.boolean(),
  grader_count: z.number(),
  grader_names_visible_to_final_grader: z.boolean(),
  graders_anonymous_to_graders: z.boolean(),
  grades_published: z.boolean(),
  grading_standard_id: z.string().nullable(),
  grading_type: z.union([z.literal('points'), z.literal('percent'), z.literal('letter_grade')]),
  group_category_id: z.string().nullable(),
  has_overrides: z.boolean(),
  has_submitted_submissions: z.boolean(),
  hide_in_gradebook: z.boolean(), // not used in SpeedGrader
  important_dates: z.boolean(),
  integration_data: z.object({}),
  integration_id: z.string().nullable(),
  intra_group_peer_reviews: z.boolean(),
  is_quiz_assignment: z.boolean(),
  lock_at: z.string().nullable(),
  locked_for_user: z.boolean(),
  lti_context_id: z.string(),
  max_name_length: z.number(),
  moderated_grading: z.boolean(),
  module_ids: z.array(z.string()).nullable(),
  module_positions: z.array(z.number()),
  muted: z.boolean(),
  name: z.string(),
  omit_from_final_grade: z.boolean(),
  only_visible_to_overrides: z.boolean(),
  original_assignment_id: z.string().nullable(),
  original_assignment_name: z.string().nullable(),
  original_course_id: z.string().nullable(),
  original_lti_resource_link_id: z.string().nullable(),
  original_quiz_id: z.string().nullable(),
  peer_reviews: z.boolean(),
  points_possible: z.number(),
  position: z.number(),
  post_to_sis: z.boolean(),
  published: z.boolean(),
  require_lockdown_browser: z.boolean(),
  secure_params: z.string(),
  sis_assignment_id: z.string().nullable(),
  submission_types: z.array(z.string()),
  submissions_download_url: z.string(),
  unlock_at: z.string().nullable(), // not used in SpeedGrader
  unpublishable: z.boolean(),
  updated_at: z.string(),
  workflow_state: ZWorkflowState,
})

export type Assignment = z.infer<typeof ZAssignment>

export const ZEnrollment = z.object({
  associated_user_id: z.string().nullable(), // not used in SpeedGrader
  course_id: z.string(),
  course_integration_id: z.string().nullable(), // not used in SpeedGrader
  course_section_id: z.string(),
  created_at: z.string(),
  end_at: z.string().nullable(), // not used in SpeedGrader
  enrollment_state: z.union([z.literal('active')]),
  html_url: z.string(), // not used in SpeedGrader
  id: z.string(),
  last_activity_at: z.string().nullable(), // not used in SpeedGrader
  last_attended_at: z.string().nullable(), // not used in SpeedGrader
  limit_privileges_to_course_section: z.boolean(), // not used in SpeedGrader
  role_id: z.string(),
  root_account_id: z.string(),
  section_integration_id: z.string().nullable(), // not used in SpeedGrader
  sis_account_id: z.string().nullable(),
  sis_course_id: z.string().nullable(),
  sis_import_id: z.string().nullish(), // not used in SpeedGrader
  sis_section_id: z.string().nullable(),
  sis_user_id: z.string().nullish(), // not used in SpeedGrader
  start_at: z.string().nullable(),
  total_activity_time: z.number(), // not used in SpeedGrader
  type: z.union([z.literal('StudentEnrollment'), z.literal('StudentViewEnrollment')]),
  updated_at: z.string(),
  user_id: z.string(),
  grades: z.object({
    html_url: z.string(), // not used in SpeedGrader
    current_grade: z.number().nullable(), // not used in SpeedGrader
    current_score: z.number().nullable(), // not used in SpeedGrader
    final_grade: z.number().nullable(), // not used in SpeedGrader
    final_score: z.number().nullable(), // not used in SpeedGrader
    unposted_current_score: z.number().nullable(), // not used in SpeedGrader
    unposted_current_grade: z.number().nullable(), // not used in SpeedGrader
    unposted_final_score: z.number().nullable(), // not used in SpeedGrader
    unposted_final_grade: z.number().nullable(), // not used in SpeedGrader
  }),
  workflow_state: ZWorkflowState,
})

export type Enrollment = z.infer<typeof ZEnrollment>

export const ZSubmissionComment = z.object({
  anonymous_id: z.string(),
  attachments: z.array(ZAttachment),
  attempt: z.number().nullable(),
  author: z.object({
    id: z.string(),
    display_name: z.string(),
    avatar_image_url: z.string(),
    html_url: z.string(),
  }),
  author_id: z.string(),
  author_name: z.string().nullable(),
  avatar_path: z.string(),
  cached_attachments: z.array(ZAttachment),
  comment: z.string(),
  created_at: z.string(),
  display_updated_at: z.string().nullable(), // not used in SpeedGrader
  draft: z.boolean(),
  edited_at: z.string().nullable(),
  group_comment_id: z.string(),
  id: z.string(),
  is_read: z.boolean().nullable(),
  media_comment_id: z.string(),
  media_comment_type: z.string(),
  media_object: z.unknown().nullable(),
  posted_at: z.string().nullish(),
  publishable: z.boolean(),
  submission_comment: z.any(), // unfortunate
  updated_at: z.string(),
})

export type SubmissionComment = z.infer<typeof ZSubmissionComment>

export const ZSubmissionState = z.union([
  z.literal('not_gradeable'),
  z.literal('not_graded'),
  z.literal('graded'),
  z.literal('resubmitted'),
  z.literal('not_submitted'),
])

export type SubmissionState = z.infer<typeof ZSubmissionState>

export const ZAttachmentData = z.object({
  attachment: ZAttachment,
})

export type AttachmentData = z.infer<typeof ZAttachmentData>

export const ZGradingPeriod = z
  .object({
    close_date: z.string(),
    end_date: z.string(),
    id: z.string(),
    is_closed: z.boolean(),
    is_last: z.boolean(),
    permissions: z.object({
      read: z.boolean(),
      update: z.boolean(),
      create: z.boolean(),
      delete: z.boolean(),
    }),
    start_date: z.string(),
    title: z.string(),
    weight: z.number().nullable(),
  })
  .strict()

export type GradingPeriod = z.infer<typeof ZGradingPeriod>

export const ZGradingPeriods = z.array(ZGradingPeriod)

interface Window {
  jsonData: SpeedGraderStore
}

export const ZProvisionalCrocodocUrl = z.object({
  attachment_id: z.string(),
  crocodoc_url: z.string().nullable(),
  canvadoc_url: z.string().nullable(),
})

export type ProvisionalCrocodocUrl = z.infer<typeof ZProvisionalCrocodocUrl>

export const ZStudentSubmissionData = z.object({
  anonymous_id: z.string(),
  anonymous_name_position: z.number(),
  avatar_path: z.string(),
  enrollments: z.array(
    z.object({
      workflow_state: z.string(),
    })
  ),
  fake_student: z.boolean().nullable(),
  id: z.string(),
  index: z.number(),
  needs_provisional_grade: z.boolean(),
  provisional_crocodoc_urls: z.array(ZProvisionalCrocodocUrl),
  redo_request: z.boolean(),
  rubric_assessments: z.array(ZRubricAssessment),
  submission_state: ZSubmissionState,
  submission: ZSubmission,
  submitted_at: z.date().nullable(),
})

export type StudentSubmissionData = z.infer<typeof ZStudentSubmissionData>

export const ZStudentWithSubmission = ZStudent.extend(ZStudentSubmissionData.shape)

export type StudentWithSubmission = Student & StudentSubmissionData

export type SpeedGrader = {
  resolveStudentId: (studentId: string | null) => string | undefined
  handleGradeSubmit: (event: unknown, use_existing_score: boolean) => void
  addCommentDeletionHandler: (commentElement: JQuery, comment: SubmissionComment) => void
  addCommentSubmissionHandler: (commentElement: JQuery, comment: SubmissionComment) => void
  addSubmissionComment: (comment?: boolean) => void
  onProvisionalGradesFetched: (data: {
    needs_provisional_grade: boolean
    provisional_grades: ProvisionalGrade[]
    updated_at: string
    final_provisional_grade: {
      grade: string
    }
  }) => void
  anyUnpostedComment: () => boolean
  assessmentAuditTray?: AssessmentAuditTray | null
  attachmentIframeContents: (attachment: Attachment) => string
  beforeLeavingSpeedgrader: (event: BeforeUnloadEvent) => void
  changeToSection: (sectionId: string) => void
  currentDisplayedSubmission: () => HistoricalSubmission
  currentIndex: () => number
  currentStudent: StudentWithSubmission
  domReady: () => void
  resetReassignButton: () => void
  updateHistoryForCurrentStudent: (behavior: 'push' | 'replace') => void
  fetchProvisionalGrades: () => void
  displayExpirationWarnings: (
    aggressiveWarnings: number[],
    count: number,
    crocodocMessage: string
  ) => void
  setGradeReadOnly: (readOnly: boolean) => void
  showStudent: () => void
  initialVersion?: number
  parseDocumentQuery: () => any
  getOriginalRubricInfo: () => any
  totalStudentCount: () => number
  formatGradeForSubmission: (grade: string) => string
  skipRelativeToCurrentIndex: (skip: number) => void
  initComments: () => void
  renderAttachment: (attachment: Attachment) => void
  goToStudent: (studentIdentifier: any, historyBehavior?: 'push' | 'replace' | null) => void
  handleGradingError: (error: GradingError) => void
  handleStatePopped: (event: PopStateEvent) => void
  getStudentNameAndGrade: (student?: StudentWithSubmission) => string
  handleStudentChanged: (historyBehavior: 'push' | 'replace' | null) => void
  postPolicies?: PostPolicies
  reassignAssignment: () => void
  refreshFullRubric: () => void
  selectProvisionalGrade: (gradeId?: string, existingGrade?: boolean) => void
  setCurrentStudentRubricAssessments: () => void
  setReadOnly: (readOnly: boolean) => void
  renderSubmissionPreview: () => void
  renderComment: (
    commentData: SubmissionComment,
    incomingOpts?: CommentRenderingOptions
  ) => JQuery | undefined
  showSubmission: () => void
  showSubmissionDetails: () => void
  tearDownAssessmentAuditTray?: () => void
  renderLtiLaunch: (
    $iframe_holder: JQuery,
    lti_retrieve_url: string,
    submission: HistoricalSubmission
  ) => void
  setCurrentStudentAvatar: () => void
  setActiveProvisionalGradeFields: (options?: {
    grade?: null | Partial<ProvisionalGrade>
    label?: string | null
  }) => void
  handleSubmissionSelectionChange: () => void
  isGradingTypePercent: () => boolean
  jsonReady: () => void
  setInitiallyLoadedStudent: () => void
  setupGradeLoadingSpinner: () => void
  next: () => void
  prev: () => void
  refreshSubmissionsToView: () => void
  renderProvisionalGradeSelector: (options?: {showingNewStudent?: boolean}) => void
  revertFromFormSubmit: (options?: {draftComment?: boolean; errorSubmitting?: boolean}) => void
  setUpAssessmentAuditTray: () => void
  setUpRubricAssessmentTrayWrapper: () => void
  saveRubricAssessment: (
    rubricAssessmentData: {[key: string]: string | boolean | number},
    jqueryElement?: JQuery<HTMLElement>
  ) => void
  shouldParseGrade: () => boolean
  showDiscussion: () => void
  showRubric: (options?: {validateEnteredData?: boolean}) => void
  updateSelectMenuStatus: (student: any) => void
  renderCommentAttachment: (
    comment: SubmissionComment,
    attachmentData: Attachment | AttachmentData,
    options: any
  ) => JQuery
  updateStatsInHeader: () => void
  setOrUpdateSubmission: (submission: any) => {
    rubric_assessments: {
      id: string
    }[]
  }
  generateWarningTimings: (count: number) => number[]
  emptyIframeHolder: (element?: JQuery) => void
  showGrade: () => void
  toggleFullRubric: (opt?: string) => void
  updateWordCount: (count?: number | null) => void
  populateTurnitin: (
    submission: HistoricalSubmission,
    assetString: string,
    turnitinAsset_: SubmissionOriginalityData,
    $turnitinScoreContainer: JQuery,
    $turnitinInfoContainer_: JQuery,
    isMostRecent: boolean
  ) => void
  populateVeriCite: (
    submission: HistoricalSubmission,
    assetString: string,
    vericiteAsset: SubmissionOriginalityData,
    $vericiteScoreContainer: JQuery,
    $vericiteInfoContainer: JQuery,
    isMostRecent: boolean
  ) => void
  current_prov_grade_index?: string
  getGradeToShow: (submission: Submission) => Grade
  setupProvisionalGraderDisplayNames: () => void
  handleProvisionalGradeSelected: (params: {
    selectedGrade?: {
      provisional_grade_id: string
    }
    isNewGrade: boolean
  }) => void
  compareStudentsBy: (
    f: (student1: StudentWithSubmission) => number
  ) => (studentA: StudentWithSubmission, studentB: StudentWithSubmission) => any
  plagiarismIndicator: (options: {
    plagiarismAsset: SubmissionOriginalityData
    reportUrl?: null | string
    tooltip: string
  }) => JQuery
  loadSubmissionPreview: (
    attachment: Attachment | null,
    submission: HistoricalSubmission | null
  ) => void
  hasUnsubmittedRubric: (originalRubric: any) => boolean
  refreshGrades: (
    callback: (submission: Submission) => void,
    retry?: (
      submission: Submission,
      originalSubmission: Submission,
      numRequests: number
    ) => boolean,
    retryDelay?: number
  ) => void
  setState: (state: any) => void
}

export type Grade = {
  entered: string
  pointsDeducted?: any
  adjusted?: any
}

export type GradingError = {
  errors?: {
    error_code:
      | 'ASSIGNMENT_LOCKED'
      | 'MAX_GRADERS_REACHED'
      | 'PROVISIONAL_GRADE_INVALID_SCORE'
      | 'PROVISIONAL_GRADE_MODIFY_SELECTED'
  }
}

type GradeLoadingStateMap = {
  [userId: string]: boolean
}

export type GradeLoadingData = {
  currentStudentId: string
  gradesLoading: GradeLoadingStateMap
}

export type CourseSection = {
  id: string
  name: string
}

export const ZSpeedGraderEnrollment = z.object({
  course_section_id: z.string(),
  user_id: z.string(),
  workflow_state: z.string(),
})

export type SpeedGraderEnrollmentType = z.infer<typeof ZSpeedGraderEnrollment>

export const ZSpeedGraderStudent = z.object({
  fake_student: z.boolean(),
  id: z.string(),
  name: z.string(),
  rubric_assessments: z.array(ZRubricAssessment),
  sortable_name: z.string(),
})

export type SpeedGraderStudentType = z.infer<typeof ZSpeedGraderStudent>

export const ZTurnItInSettings = z.object({
  exclude_biblio: z.string(),
  exclude_quoted: z.string(),
  exclude_type: z.string(),
  exclude_value: z.string(),
  internet_check: z.string(),
  journal_check: z.string(),
  originality_report_visibility: z.string(),
  s_paper_check: z.string(),
  submit_papers_to: z.string(),
})

export type TurnItInSettingsType = z.infer<typeof ZTurnItInSettings>

export const ZQuiz = z.object({anonymous_submissions: z.boolean()})

export type Quiz = z.infer<typeof ZQuiz>

export const ZAssignedAssessments = z.object({
  anonymizedUser: z.object({displayName: z.string(), _id: z.string()}).nullable(),
  anonymousId: z.string().nullable(),
  assetId: z.string(),
  assetSubmissionType: z.string().nullable(),
  workflowState: z.string(),
})

export type AssignedAssessments = z.infer<typeof ZAssignedAssessments>

export const ZSpeedGraderContext = z.object({
  active_course_sections: z.array(z.object({id: z.string(), name: z.string()})),
  concluded: z.boolean(),
  enrollments: z.array(ZSpeedGraderEnrollment),
  id: z.string(),
  quiz: ZQuiz.nullable(),
  rep_for_student: z.record(z.string(), z.string()),
  students: z.array(ZSpeedGraderStudent),
})

export type SpeedGraderContextType = z.infer<typeof ZSpeedGraderContext>

export const ZSpeedGraderResponse = z
  .object({
    ab_guid: z.array(z.string()), // not used in SpeedGrader
    all_day_date: z.string().nullable(), // not used in SpeedGrader
    all_day: z.boolean(), // not used in SpeedGrader
    allowed_attempts: z.number().nullable(),
    allowed_extensions: z.array(z.unknown()), // not used in SpeedGrader
    annotatable_attachment_id: z.string().nullable(),
    anonymize_graders: z.boolean(),
    anonymize_students: z.boolean(),
    anonymous_grading: z.boolean(),
    anonymous_instructor_annotations: z.boolean(),
    anonymous_peer_reviews: z.boolean(),
    assignment_group_id: z.string(),
    automatic_peer_reviews: z.boolean(), // not used in SpeedGrader
    cloned_item_id: z.string().nullable(), // not used in SpeedGrader
    context_id: z.string(),
    context_type: z.string(),
    context: ZSpeedGraderContext,
    copied: z.boolean(), // not used in SpeedGrader
    could_be_locked: z.boolean(), // not used in SpeedGrader
    created_at: z.string(),
    description: z.string(), // not used in SpeedGrader
    due_at: z.string().nullable(),
    duplicate_of_id: z.string().nullable(), // not used in SpeedGrader
    duplication_started_at: z.string().nullable(), // not used in SpeedGrader
    final_grader_id: z.string().nullable(),
    freeze_on_copy: z.boolean(), // not used in SpeedGrader
    grade_group_students_individually: z.boolean(), // not used in SpeedGrader
    grader_comments_visible_to_graders: z.boolean(),
    grader_count: z.number(),
    grader_names_visible_to_final_grader: z.boolean(),
    grader_section_id: z.string().nullable(), // not used in SpeedGrader
    graders_anonymous_to_graders: z.boolean(),
    grades_published_at: z.null(),
    grading_standard_id: z.string().nullable(), // not used in SpeedGrader
    grading_type: z.string(),
    group_category_id: z.string().nullable(), // not used in SpeedGrader
    group_category: z.null(), // not used in SpeedGrader
    GROUP_GRADING_MODE: z.boolean(),
    has_sub_assignments: z.boolean(), // not used in SpeedGrader
    hide_in_gradebook: z.boolean(), // not used in SpeedGrader
    id: z.string(),
    important_dates: z.boolean(), // not used in SpeedGrader
    importing_started_at: z.null(), // not used in SpeedGrader
    integration_data: z.object({}), // not used in SpeedGrader
    integration_id: z.string().nullable(),
    intra_group_peer_reviews: z.boolean(), // not used in SpeedGrader
    line_item_resource_id: z.string().nullable(), // not used in SpeedGrader
    line_item_tag: z.null(), // not used in SpeedGrader
    lock_at: z.null(), // not used in SpeedGrader
    lti_context_id: z.string(), // not used in SpeedGrader
    lti_resource_link_custom_params: z.null(), // not used in SpeedGrader
    lti_resource_link_lookup_uuid: z.string().nullish(), // not used in SpeedGrader
    lti_resource_link_url: z.null(), // not used in SpeedGrader
    mastery_score: z.null(), // not used in SpeedGrader
    max_score: z.null(), // not used in SpeedGrader
    migrate_from_id: z.string().nullable(), // not used in SpeedGrader
    migration_id: z.string().nullable(), // not used in SpeedGrader
    min_score: z.null(),
    moderated_grading: z.boolean(),
    muted: z.boolean(),
    omit_from_final_grade: z.boolean(),
    only_visible_to_overrides: z.boolean(), // not used in SpeedGrader
    parent_assignment_id: z.string().nullable(), // not used in SpeedGrader
    peer_review_count: z.number(), // not used in SpeedGrader
    peer_reviews_assigned: z.boolean(), // not used in SpeedGrader
    peer_reviews_due_at: z.null(), // not used in SpeedGrader
    peer_reviews: z.boolean(), // not used in SpeedGrader
    points_possible: z.number(),
    position: z.number(),
    post_manually: z.boolean(), // not used in SpeedGrader
    post_to_sis: z.boolean(), // not used in SpeedGrader
    quiz_lti: z.boolean(),
    root_account_id: z.string(),
    settings: z.null(),
    sis_source_id: z.string().nullable(), // not used in SpeedGrader
    sub_assignment_tag: z.null(), // not used in SpeedGrader
    submission_types: z.string(),
    submissions_downloads: z.number(), // not used in SpeedGrader
    submissions: z.array(ZSubmission),
    time_zone_edited: z.string(), // not used in SpeedGrader
    title: z.string(),
    too_many_quiz_submissions: z.boolean(),
    turnitin_enabled: z.boolean(),
    turnitin_id: z.string().nullable(),
    turnitin_settings: ZTurnItInSettings,
    unlock_at: z.null(), // not used in SpeedGrader
    updated_at: z.string(),
    vericite_enabled: z.boolean(),
    workflow_state: z.string(),
  })
  .strict()

export type SpeedGraderResponse = z.infer<typeof ZSpeedGraderResponse>

export type SpeedGraderStore = SpeedGraderResponse & {
  context: {
    active_course_sections: CourseSection[]
    enrollments: Enrollment[]
    grading_periods: GradingPeriod[]
    students: StudentWithSubmission[]
  }
  gradingPeriods: Record<string, GradingPeriod>
  rubric_association?: unknown
  studentEnrollmentMap: any
  studentMap: any
  studentSectionIdsMap: any
  studentsWithSubmissions: StudentWithSubmission[]
  submissionsMap: Record<string, Submission>
}

export type DocumentPreviewOptions = {
  attachment_id: string
  attachment_preview_processing: boolean
  attachment_view_inline_ping_url: string | null
  crocodoc_session_url?: string
  height: string
  id: string
  mimeType: string
  submission_id: string
}

export const ZScoringSnapshot = z.object({
  fudge_points: z.number(),
  last_question_touched: z.string().nullable(),
  question_updates: z.record(z.string(), z.unknown()),
  user_id: z.string().nullable(),
  version_number: z.number(),
})

export type ScoringSnapshot = z.infer<typeof ZScoringSnapshot>

export type CommentRenderingOptions = {
  commentAttachmentBlank: JQuery<HTMLElement>
  commentBlank: JQuery<HTMLElement>
  hideStudentNames?: boolean
}
