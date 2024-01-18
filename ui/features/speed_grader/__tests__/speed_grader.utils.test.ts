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
import type {Student} from '../../../api.d'

// For the ts-expect-errors below... speedgrader does a lot of wacky things that don't fit our defined types, so the
// enrollments that get added to Students are not the same shape Enrollments definition we have.
const students: Student[] = [
  {
    created_at: '',
    email: '',
    group_ids: [],
    id: '0',
    short_name: 'John',
    enrollments: [
      {
        user_id: '0',
        // @ts-expect-error
        workflow_state: 'active',
        course_section_id: '0',
      },
      {
        user_id: '0',
        // @ts-expect-error
        workflow_state: 'active',
        course_section_id: '1',
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
    email: '',
    group_ids: [],
    id: '1',
    short_name: 'John',
    enrollments: [
      // @ts-expect-error
      {
        user_id: '1',
        workflow_state: 'completed',
        course_section_id: '0',
      },
      // @ts-expect-error
      {
        user_id: '1',
        workflow_state: 'completed',
        course_section_id: '1',
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
  {
    created_at: '',
    email: '',
    group_ids: [],
    id: '2',
    short_name: 'John',
    enrollments: [
      {
        user_id: '2',
        // @ts-expect-error
        workflow_state: 'active',
        course_section_id: '0',
      },
      // @ts-expect-error
      {
        user_id: '2',
        workflow_state: 'completed',
        course_section_id: '1',
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

// @ts-ignore
const keyBy = (array, key) => array.reduce((r, x) => ({...r, [key ? x[key] : x]: x}), {})
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
