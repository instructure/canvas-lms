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

import {WorkflowState} from 'api'
import {http, HttpResponse} from 'msw'
import {SetupServer} from 'msw/node'
import {RemovableEnrollment} from '../EditRolesModal'

export const AVAILABLE_ROLES = [
  {
    addable_by_user: true,
    base_role_name: 'Student',
    deleteable_by_user: true,
    id: '1',
    label: 'Student',
    name: 'Student',
    plural_label: 'Students',
  },
  {
    addable_by_user: true,
    base_role_name: 'Teacher',
    deleteable_by_user: true,
    id: '2',
    label: 'Teacher',
    name: 'Teacher',
    plural_label: 'Teachers',
  },
  {
    addable_by_user: true,
    base_role_name: 'TA',
    deleteable_by_user: true,
    id: '3',
    label: 'TA',
    name: 'TA',
    plural_label: 'TAs',
  },
]

export const USER_ID = '1'

type EnrollmentStates = 'active' | 'inactive' | 'completed' | 'invited'
type StudentEnrollmentType = 'StudentEnrollment' | 'StudentViewEnrollment'
// a generic enrollment that can be extended into additional enrollments
// (aka typescript-friendly object)
export const GENERIC_ENROLLMENT = {
  associated_user_id: null,
  course_integration_id: null,
  created_at: '2024-01-01T00:00:00Z',
  end_at: null,
  enrollment_state: 'active' as EnrollmentStates,
  root_account_id: '1',
  start_at: '2024-01-01T00:00:00Z',
  sis_account_id: null,
  sis_course_id: null,
  sis_import_id: null,
  sis_section_id: null,
  sis_user_id: null,
  type: 'StudentEnrollment' as StudentEnrollmentType,
  updated_at: '2024-01-01T00:00:00Z',
  user_id: USER_ID,
  workflow_state: 'active' as WorkflowState,
  html_url: '',
  grades: {
    html_url: '',
    current_grade: null,
    current_score: null,
    final_grade: null,
    final_score: null,
    unposted_current_score: null,
    unposted_current_grade: null,
    unposted_final_score: null,
    unposted_final_grade: null,
  },
  last_activity_at: null,
  last_attended_at: null,
  total_activity_time: 0,
  role: '',
  section_integration_id: null,
  user: {},
}

export function setupDeleteMocks(
  server: SetupServer,
  enrollments: RemovableEnrollment[],
  roleId: string,
) {
  const paths: string[] = []
  const deletedEnrollments: RemovableEnrollment[] = []
  enrollments.forEach(enrollment => {
    if (roleId === enrollment.role_id) return
    const deletePath = `/unenroll/${enrollment.id}`
    server.use(
      http.delete(deletePath, () => {
        return HttpResponse.json({enrollment: enrollment})
      }),
    )
    paths.push(deletePath)
    deletedEnrollments.push(enrollment)
  })
  return {
    deletedEnrollments,
    deletedPaths: paths,
  }
}

export function setupPostMocks(
  server: SetupServer,
  enrollments: RemovableEnrollment[],
  roleId: string,
) {
  const newEnrollments: RemovableEnrollment[] = []
  const paths: string[] = []
  const existing_section_ids = enrollments
    .filter(en => en.role_id === roleId)
    .map(en => en.course_section_id)
  enrollments.forEach(enrollment => {
    // if-statement copied straight from createEnrollment
    if (
      existing_section_ids.includes(enrollment.course_section_id) ||
      enrollment.role_id === roleId
    ) {
      return
    }
    const postPath = `/api/v1/sections/${enrollment.course_section_id}/enrollments`
    const newEnrollment = {
      ...enrollment,
      role_id: roleId,
    }
    server.use(
      http.post(postPath, () => {
        return HttpResponse.json(newEnrollment)
      }),
    )
    newEnrollments.push({...newEnrollment, can_be_removed: true})
    paths.push(postPath)
  })
  return {
    newEnrollments,
    postPaths: paths,
  }
}
