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

import {Enrollment as ApiEnrollment, WorkflowState} from 'api.d'
import {Enrollment} from './getEnrollments'

export const transformEnrollment = (
  enrollment: Enrollment,
): ApiEnrollment & Record<string, unknown> => ({
  associated_user_id: enrollment.associatedUser?._id ?? null,
  course_id: enrollment.course?._id ?? '',
  course_section_id: enrollment.courseSectionId ?? '',
  created_at: enrollment.createdAt ?? '',
  end_at: enrollment.endAt,
  enrollment_state: enrollment.enrollmentState as 'active' | 'completed' | 'inactive' | 'invited',
  html_url: enrollment.htmlUrl ?? '',
  id: enrollment._id,
  last_activity_at: enrollment.lastActivityAt,
  limit_privileges_to_course_section: enrollment.limitPrivilegesToCourseSection ?? false,
  role_id: enrollment.role?._id ?? '',
  sis_section_id: enrollment.sisSectionId,
  sis_user_id: null, // will be set from user object
  start_at: enrollment.startAt,
  type: enrollment.type as 'StudentEnrollment' | 'StudentViewEnrollment',
  updated_at: enrollment.updatedAt ?? '',
  user_id: enrollment.userId ?? '',
  workflow_state: enrollment.state as WorkflowState,
  grades: {
    // grades are represented as strings in the backend, but ApiEnrollment defines them as numbers
    // so we cast them to unknown first to avoid type errors and then to number
    html_url: enrollment.grades.htmlUrl ?? '',
    current_grade: enrollment.grades.currentGrade as unknown as number,
    current_score: enrollment.grades.currentScore ?? null,
    final_grade: enrollment.grades.finalGrade as unknown as number,
    final_score: enrollment.grades.finalScore ?? null,
    unposted_current_grade: enrollment.grades.unpostedCurrentGrade as unknown as number,
    unposted_current_score: enrollment.grades.unpostedCurrentScore ?? null,
    unposted_final_grade: enrollment.grades.unpostedFinalGrade as unknown as number,
    unposted_final_score: enrollment.grades.unpostedFinalScore ?? null,
  },

  // The following attributes are provided by the legacy API
  role: enrollment.role?.name,

  // The following attributes are not used at all
  // only defining them to satisfy the type
  course_integration_id: null,
  last_attended_at: null,
  section_integration_id: null,
  sis_account_id: null,
  sis_course_id: null,
  sis_import_id: null,
  total_activity_time: 0,
  root_account_id: '',
})
