/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {isStudentConcluded} from '../jquery/speed_grader.utils'
import type {Student, Enrollment, WorkflowState} from '../../../api.d'

type SpeedGraderEnrollment = Enrollment

const students: Student[] = [
  {
    created_at: '',
    email: null,
    group_ids: [],
    id: '0',
    short_name: 'John',
    integration_id: null,
    login_id: 'john',
    sis_import_id: null,
    sis_user_id: null,
    enrollments: [
      {
        associated_user_id: null,
        course_id: '1',
        course_integration_id: null,
        course_section_id: '0',
        created_at: '2023-01-01T00:00:00Z',
        end_at: null,
        enrollment_state: 'active',
        grades: {
          html_url: '',
          current_score: null,
          final_score: null,
          current_grade: null,
          final_grade: null,
          unposted_current_score: null,
          unposted_current_grade: null,
          unposted_final_score: null,
          unposted_final_grade: null,
        },
        html_url: '',
        id: '1',
        last_activity_at: null,
        limit_privileges_to_course_section: false,
        role_id: '1',
        root_account_id: '1',
        section_integration_id: null,
        sis_account_id: null,
        sis_course_id: null,
        sis_import_id: null,
        sis_section_id: null,
        sis_user_id: null,
        start_at: null,
        total_activity_time: 0,
        type: 'StudentEnrollment',
        updated_at: '2023-01-01T00:00:00Z',
        user_id: '0',
        workflow_state: 'active' as WorkflowState,
        last_attended_at: null,
      },
      {
        associated_user_id: null,
        course_id: '1',
        course_integration_id: null,
        course_section_id: '1',
        created_at: '2023-01-01T00:00:00Z',
        end_at: null,
        enrollment_state: 'active',
        grades: {
          html_url: '',
          current_score: null,
          final_score: null,
          current_grade: null,
          final_grade: null,
          unposted_current_score: null,
          unposted_current_grade: null,
          unposted_final_score: null,
          unposted_final_grade: null,
        },
        html_url: '',
        id: '2',
        last_activity_at: null,
        last_attended_at: null,
        limit_privileges_to_course_section: false,
        role_id: '1',
        root_account_id: '1',
        section_integration_id: null,
        sis_account_id: null,
        sis_course_id: null,
        sis_import_id: null,
        sis_section_id: null,
        sis_user_id: null,
        start_at: null,
        total_activity_time: 0,
        type: 'StudentEnrollment',
        updated_at: '2023-01-01T00:00:00Z',
        user_id: '0',
        workflow_state: 'active' as WorkflowState,
      },
    ],
    first_name: 'Jim',
    last_name: 'Doe',
    name: 'Jim Doe',
    index: 0,
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
    sortable_name: 'Doe, Jim',
    total_grade: 100,
  },
  {
    created_at: '',
    email: null,
    group_ids: [],
    id: '1',
    short_name: 'John',
    integration_id: null,
    login_id: 'bob',
    sis_import_id: null,
    sis_user_id: null,
    enrollments: [
      {
        user_id: '1',
        workflow_state: 'completed' as const,
        course_section_id: '0',
        last_attended_at: null,
      } as SpeedGraderEnrollment,
      {
        user_id: '1',
        workflow_state: 'completed' as const,
        course_section_id: '1',
        last_attended_at: null,
      } as SpeedGraderEnrollment,
    ],
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
  },
  {
    created_at: '',
    email: null,
    group_ids: [],
    id: '2',
    short_name: 'John',
    integration_id: null,
    login_id: 'bob2',
    sis_import_id: null,
    sis_user_id: null,
    enrollments: [
      {
        associated_user_id: null,
        course_id: '1',
        course_integration_id: null,
        course_section_id: '0',
        created_at: '2023-01-01T00:00:00Z',
        end_at: null,
        enrollment_state: 'active',
        grades: {
          html_url: '',
          current_score: null,
          final_score: null,
          current_grade: null,
          final_grade: null,
          unposted_current_score: null,
          unposted_current_grade: null,
          unposted_final_score: null,
          unposted_final_grade: null,
        },
        html_url: '',
        id: '3',
        last_activity_at: null,
        last_attended_at: null,
        limit_privileges_to_course_section: false,
        role_id: '1',
        root_account_id: '1',
        section_integration_id: null,
        sis_account_id: null,
        sis_course_id: null,
        sis_import_id: null,
        sis_section_id: null,
        sis_user_id: null,
        start_at: null,
        total_activity_time: 0,
        type: 'StudentEnrollment',
        updated_at: '2023-01-01T00:00:00Z',
        user_id: '2',
        workflow_state: 'active' as WorkflowState,
      },
      {
        associated_user_id: null,
        course_id: '1',
        course_integration_id: null,
        course_section_id: '1',
        created_at: '2023-01-01T00:00:00Z',
        end_at: null,
        enrollment_state: 'completed',
        grades: {
          html_url: '',
          current_score: null,
          final_score: null,
          current_grade: null,
          final_grade: null,
          unposted_current_score: null,
          unposted_current_grade: null,
          unposted_final_score: null,
          unposted_final_grade: null,
        },
        html_url: '',
        id: '4',
        last_activity_at: null,
        last_attended_at: null,
        limit_privileges_to_course_section: false,
        role_id: '1',
        root_account_id: '1',
        section_integration_id: null,
        sis_account_id: null,
        sis_course_id: null,
        sis_import_id: null,
        sis_section_id: null,
        sis_user_id: null,
        start_at: null,
        total_activity_time: 0,
        type: 'StudentEnrollment',
        updated_at: '2023-01-01T00:00:00Z',
        user_id: '2',
        workflow_state: 'completed' as WorkflowState,
      },
    ],
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
  },
]

const keyBy = <T extends Record<string, unknown>>(array: T[], key: keyof T): Record<string, T> =>
  array.reduce((r, x) => ({...r, [String(x[key])]: x}), {})
const studentMap = keyBy(students, 'id')

describe('isStudentConcluded', () => {
  it('returns false if there is no student map', () => {
    expect(isStudentConcluded(null, '0', null)).toBe(false)
  })

  it('returns false if the student is not concluded in any enrollments and we do not have a specific section', () => {
    expect(isStudentConcluded(studentMap, '0', null)).toBe(false)
  })

  it('returns false if the student is not concluded in at least one enrollment and we do not have a specific version', () => {
    expect(isStudentConcluded(studentMap, '2', null)).toBe(false)
  })

  it('returns true if the student is concluded in all enrollments and we do not have a specific section', () => {
    expect(isStudentConcluded(studentMap, '1', null)).toBe(true)
  })

  it('returns false if the student is not concluded in this specific section, but is in another', () => {
    expect(isStudentConcluded(studentMap, '2', '0')).toBe(false)
  })

  it('return true if the student is concluded in this specific section, but active in another', () => {
    expect(isStudentConcluded(studentMap, '2', '1')).toBe(true)
  })
})
