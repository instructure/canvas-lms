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
import type {Enrollment} from 'api'
import type {Student} from '../../../../../api.d'
import type {Filter, EnrollmentFilter} from '../gradebook.d'

export const enrollment: Enrollment = {
  associated_user_id: null,
  course_id: '1',
  course_integration_id: null,
  course_section_id: '',
  created_at: '',
  end_at: null,
  enrollment_state: 'active',
  html_url: '',
  id: '',
  last_activity_at: null,
  last_attended_at: null,
  limit_privileges_to_course_section: true,
  role_id: '',
  root_account_id: '',
  section_integration_id: null,
  sis_account_id: null,
  sis_course_id: null,
  sis_import_id: null,
  sis_section_id: null,
  sis_user_id: null,
  start_at: null,
  total_activity_time: 0,
  type: 'StudentEnrollment',
  updated_at: '',
  user_id: '',
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
  workflow_state: 'completed',
}

export const student: Student = {
  created_at: '',
  email: '',
  group_ids: [],
  id: '1',
  integration_id: '',
  login_id: '',
  short_name: '',
  sis_import_id: '',
  sis_user_id: null,
  enrollments: [],
  first_name: '',
  last_name: '',
  name: 'Jim Doe',
  index: 0,
  section_ids: [],
  anonymous_name: '',
  computed_current_score: 100,
  computed_final_score: 100,
  cssClass: '',
  displayName: '',
  initialized: false,
  isConcluded: false,
  isInactive: false,
  loaded: false,
  sections: [],
  sortable_name: '',
  total_grade: 100,
}

export const student2: Student = {
  created_at: '',
  email: '',
  group_ids: [],
  id: '2',
  integration_id: '',
  login_id: '',
  short_name: 'John',
  sis_import_id: '',
  sis_user_id: null,
  enrollments: [],
  first_name: 'Bob',
  last_name: 'Smith',
  name: 'Bob Smith',
  index: 1,
  section_ids: [],
  anonymous_name: '',
  computed_current_score: 100,
  computed_final_score: 100,
  cssClass: '',
  displayName: 'Jim Doe',
  initialized: false,
  isConcluded: false,
  isInactive: false,
  loaded: false,
  sections: [],
  sortable_name: 'Smith, Bob',
  total_grade: 100,
}

export const appliedFilters: Filter[] = [
  {
    id: '1',
    type: 'section',
    created_at: '',
    value: '',
  },
]
export const enrollmentFilter: EnrollmentFilter = {
  concluded: false,
  inactive: false,
}
