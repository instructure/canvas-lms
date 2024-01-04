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
import {z} from 'zod'

export const SpeedGraderSubmissionHistoryEntry = z.object({
  // compare with SpeedGraderSubmission?
  submission: z.object({
    id: z.string(),
    body: z.any(),
    url: z.any(),
    attachment_id: z.any(),
    grade: z.any(),
    score: z.any(),
    submitted_at: z.any(),
    assignment_id: z.string(),
    user_id: z.string(),
    submission_type: z.any(),
    workflow_state: z.string(),
    created_at: z.string(),
    updated_at: z.string(),
    group_id: z.any(),
    attachment_ids: z.any(),
    processed: z.any(),
    grade_matches_current_submission: z.any(),
    published_score: z.any(),
    published_grade: z.any(),
    graded_at: z.any(),
    student_entered_score: z.any(),
    grader_id: z.any(),
    media_comment_id: z.any(),
    media_comment_type: z.any(),
    quiz_submission_id: z.any(),
    submission_comments_count: z.any(),
    attempt: z.any(),
    media_object_id: z.any(),
    turnitin_data: z.object({}),
    cached_due_date: z.any(),
    excused: z.any(),
    graded_anonymously: z.any(),
    late_policy_status: z.any(),
    points_deducted: z.any(),
    grading_period_id: z.any(),
    seconds_late_override: z.any(),
    lti_user_id: z.any(),
    anonymous_id: z.string(),
    last_comment_at: z.any(),
    extra_attempts: z.any(),
    posted_at: z.any(),
    cached_quiz_lti: z.boolean(),
    cached_tardiness: z.any(),
    course_id: z.string(),
    root_account_id: z.string(),
    redo_request: z.boolean(),
    resource_link_lookup_uuid: z.any(),
    proxy_submitter_id: z.any(),
    custom_grade_status_id: z.any(),
    sticker: z.any(),
  }),
})

export const SpeedGraderSubmission = z.object({
  id: z.string(),
  grade: z.any(),
  score: z.any(),
  submitted_at: z.any(),
  assignment_id: z.string(),
  user_id: z.string(),
  submission_type: z.any(),
  workflow_state: z.string(),
  updated_at: z.string(),
  grade_matches_current_submission: z.any(),
  graded_at: z.any(),
  attempt: z.any(),
  turnitin_data: z.object({}),
  cached_due_date: z.any(),
  excused: z.any(),
  points_deducted: z.any(),
  grading_period_id: z.any(),
  posted_at: z.any(),
  redo_request: z.boolean(),
  resource_link_lookup_uuid: z.any(),
  custom_grade_status_id: z.any(),
  submission_history: z.array(SpeedGraderSubmissionHistoryEntry),
  late: z.boolean(),
  external_tool_url: z.any(),
  entered_score: z.any(),
  entered_grade: z.any(),
  seconds_late: z.number(),
  missing: z.boolean(),
  late_policy_status: z.any(),
  word_count: z.any(),
  from_enrollment_type: z.string(),
  has_postable_comments: z.boolean(),
  submission_comments: z.array(z.unknown()),
  proxy_submitter: z.any(),
  proxy_submitter_id: z.any(),
  attachments: z.array(z.unknown()),
})

export type SpeedGraderSubmissionType = z.infer<typeof SpeedGraderSubmission>

export const SpeedGraderEnrollment = z.object({
  user_id: z.string(),
  workflow_state: z.string(),
  course_section_id: z.string(),
})

export type SpeedGraderEnrollmentType = z.infer<typeof SpeedGraderEnrollment>

export const SpeedGraderStudent = z.object({
  id: z.string(),
  name: z.string(),
  sortable_name: z.string(),
  rubric_assessments: z.array(z.unknown()),
  fake_student: z.boolean(),
})

export type SpeedGraderStudentType = z.infer<typeof SpeedGraderStudent>

export const TurnItInSettings = z.object({
  originality_report_visibility: z.string(),
  s_paper_check: z.string(),
  internet_check: z.string(),
  journal_check: z.string(),
  exclude_biblio: z.string(),
  exclude_quoted: z.string(),
  exclude_type: z.string(),
  exclude_value: z.string(),
  submit_papers_to: z.string(),
})

export type TurnItInSettingsType = z.infer<typeof TurnItInSettings>

export const Quiz = z.object({anonymous_submissions: z.boolean()})

export const SpeedGraderContext = z.object({
  id: z.string(),
  concluded: z.boolean(),
  rep_for_student: z.record(z.string(), z.string()),
  students: z.array(SpeedGraderStudent),
  active_course_sections: z.array(z.object({id: z.string(), name: z.string()})),
  enrollments: z.array(SpeedGraderEnrollment),
  quiz: z.union([Quiz, z.any()]),
})

export type SpeedGraderContextType = z.infer<typeof SpeedGraderContext>

export const SpeedGraderResponse = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  due_at: z.any(),
  unlock_at: z.any(),
  lock_at: z.any(),
  points_possible: z.number(),
  min_score: z.any(),
  max_score: z.any(),
  mastery_score: z.any(),
  grading_type: z.string(),
  submission_types: z.string(),
  workflow_state: z.string(),
  context_id: z.string(),
  context_type: z.string(),
  assignment_group_id: z.string(),
  grading_standard_id: z.any(),
  created_at: z.string(),
  updated_at: z.string(),
  group_category: z.any(),
  submissions_downloads: z.number(),
  peer_review_count: z.number(),
  peer_reviews_due_at: z.any(),
  peer_reviews_assigned: z.boolean(),
  peer_reviews: z.boolean(),
  automatic_peer_reviews: z.boolean(),
  all_day: z.boolean(),
  all_day_date: z.any(),
  could_be_locked: z.boolean(),
  cloned_item_id: z.any(),
  position: z.number(),
  migration_id: z.any(),
  grade_group_students_individually: z.boolean(),
  anonymous_peer_reviews: z.boolean(),
  time_zone_edited: z.string(),
  turnitin_enabled: z.boolean(),
  allowed_extensions: z.array(z.unknown()),
  turnitin_settings: TurnItInSettings,
  muted: z.boolean(),
  group_category_id: z.any(),
  freeze_on_copy: z.boolean(),
  copied: z.boolean(),
  only_visible_to_overrides: z.boolean(),
  post_to_sis: z.boolean(),
  integration_id: z.any(),
  integration_data: z.object({}),
  turnitin_id: z.any(),
  moderated_grading: z.boolean(),
  grades_published_at: z.any(),
  omit_from_final_grade: z.boolean(),
  vericite_enabled: z.boolean(),
  intra_group_peer_reviews: z.boolean(),
  lti_context_id: z.string(),
  anonymous_instructor_annotations: z.boolean(),
  duplicate_of_id: z.any(),
  anonymous_grading: z.boolean(),
  graders_anonymous_to_graders: z.boolean(),
  grader_count: z.number(),
  grader_comments_visible_to_graders: z.boolean(),
  grader_section_id: z.any(),
  final_grader_id: z.any(),
  grader_names_visible_to_final_grader: z.boolean(),
  duplication_started_at: z.any(),
  importing_started_at: z.any(),
  allowed_attempts: z.union([z.number(), z.any()]),
  root_account_id: z.string(),
  sis_source_id: z.any(),
  migrate_from_id: z.any(),
  settings: z.any(),
  annotatable_attachment_id: z.any(),
  important_dates: z.boolean(),
  hide_in_gradebook: z.boolean(),
  ab_guid: z.array(z.unknown()),
  parent_assignment_id: z.any(),
  sub_assignment_tag: z.any(),
  has_sub_assignments: z.boolean(),
  lti_resource_link_custom_params: z.any(),
  lti_resource_link_lookup_uuid: z.any(),
  lti_resource_link_url: z.any(),
  line_item_resource_id: z.any(),
  line_item_tag: z.any(),
  context: SpeedGraderContext,
  anonymize_students: z.boolean(),
  anonymize_graders: z.boolean(),
  post_manually: z.boolean(),
  too_many_quiz_submissions: z.boolean(),
  submissions: z.array(SpeedGraderSubmission),
  GROUP_GRADING_MODE: z.boolean(),
  quiz_lti: z.boolean(),
})

export type SpeedGraderResponseType = z.infer<typeof SpeedGraderResponse>

export const GradingPeriod = z.object({
  is_closed: z.boolean(),
})

export type GradingPeriodType = z.infer<typeof GradingPeriod>

export const Student = z.object({
  enrollments: z.array(
    z.object({
      workflow_state: z.string(),
    })
  ),
})

export type StudentType = z.infer<typeof Student>

export type SpeedGraderStore = SpeedGraderResponseType & {
  gradingPeriods: Record<string, GradingPeriodType>
  rubric_association?: unknown
  studentEnrollmentMap: any
  studentMap: any
  studentSectionIdsMap: any
  studentsWithSubmissions: any
  submissionsMap: any
}
