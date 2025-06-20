/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Assignment as ApiAssignment, WorkflowState} from 'api.d'
import {Assignment} from './getAssignments'

export const transformAssignment = (it: Assignment): ApiAssignment => ({
  allowed_attempts: it.allowedAttempts ?? -1,
  allowed_extensions: it.allowedExtensions ?? [],
  anonymize_students: it.anonymizeStudents ?? false,
  anonymous_grading: it.anonymousGrading ?? false,
  anonymous_instructor_annotations: it.anonymousInstructorAnnotations ?? false,
  anonymous_peer_reviews: it.peerReviews?.anonymousReviews ?? false,
  assignment_group_id: it.assignmentGroupId ?? '',
  assignment_visibility: it.assignmentVisibility ?? [],
  automatic_peer_reviews: it.peerReviews?.automaticReviews ?? false,
  course_id: it.courseId ?? '',
  created_at: it.createdAt ?? '',
  due_at: it.dueAt as any,
  due_date_required: it.dueDateRequired ?? false,
  grade_group_students_individually: it.gradeGroupStudentsIndividually ?? false,
  graded_submissions_exist: it.gradedSubmissionsExist ?? false,
  grades_published: it.gradesPublished ?? false,
  grading_standard_id: it.gradingStandardId,
  grading_type: it.gradingType,
  group_category_id: it.groupCategoryId ? it.groupCategoryId.toString() : null,
  has_rubric: it.hasRubric,
  has_sub_assignments: it.hasSubAssignments,
  has_submitted_submissions: it.hasSubmittedSubmissions ?? false,
  html_url: it.htmlUrl ?? '',
  id: it._id,
  important_dates: it.importantDates ?? false,
  intra_group_peer_reviews: it.peerReviews?.intraReviews ?? false,
  lock_at: it.lockAt,
  moderated_grading: it.moderatedGradingEnabled ?? false,
  module_ids: (it.moduleItems ?? []).map(moduleItem => moduleItem.module._id),
  module_positions: (it.moduleItems ?? []).map(moduleItem => moduleItem.position),
  muted: it.muted ?? false,
  name: it.name ?? '',
  omit_from_final_grade: it.omitFromFinalGrade ?? false,
  only_visible_to_overrides: it.onlyVisibleToOverrides,
  peer_reviews: it.peerReviews?.enabled ?? false,
  points_possible: it.pointsPossible ?? 0,
  position: it.position ?? 0,
  post_manually: it.postManually ?? false,
  post_to_sis: it.postToSis ?? false,
  published: it.published ?? false,
  submission_types: it.submissionTypes ?? [],
  unlock_at: it.unlockAt,
  updated_at: it.updatedAt ?? '',
  visible_to_everyone: it.visibleToEveryone,
  workflow_state: it.state as WorkflowState,
  checkpoints:
    it.checkpoints?.map(checkpoint => ({
      tag: checkpoint.tag,
      due_at: checkpoint.dueAt,
      lock_at: checkpoint.lockAt,
      unlock_at: checkpoint.unlockAt,
      name: checkpoint.name ?? '',
      points_possible: checkpoint.pointsPossible,
      only_visible_to_overrides: checkpoint.onlyVisibleToOverrides,
      // checkpoint overrides are only used in the assignment index page
      // thus we just assign an empty array to satisfy the type, but won't fetch
      overrides: [],
    })) ?? [],

  // These attributes does not seem to be used by gradebook
  annotatable_attachment_id: undefined as any,
  can_duplicate: undefined as any,
  discussion_topic: undefined as any,
  final_grader_id: undefined as any,
  grader_comments_visible_to_graders: undefined as any,
  grader_count: undefined as any,
  grader_names_visible_to_final_grader: undefined as any,
  graders_anonymous_to_graders: undefined as any,
  // only used on assignment.overrides.length, not directly on assignments
  has_overrides: undefined as any,
  hide_in_gradebook: undefined as any,
  integration_data: undefined as any,
  integration_id: undefined as any,
  is_quiz_assignment: undefined as any,
  locked_for_user: undefined as any,
  lti_context_id: undefined as any,
  max_name_length: undefined as any,
  original_assignment_id: undefined as any,
  original_assignment_name: undefined as any,
  original_course_id: undefined as any,
  original_lti_resource_link_id: undefined as any,
  original_quiz_id: undefined as any,
  require_lockdown_browser: undefined as any,
  secure_params: undefined as any,
  sis_assignment_id: undefined as any,
  submissions_download_url: undefined as any,
  unpublishable: undefined as any,
  // Using default false since this property is required by the API type
  suppress_assignment: false,
})

// NOTES:
// Original query calls AssignmentGroupsController.index
// The following attributes are not fetched on purpose:
// - inClosedGradingPeriod is excluded by the original query
// - overrides are not included if not defined explictly

// TODO: hide_zero_point_quizzes handle!!!
