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

export const SECTIONS_DATA = [
  {id: '1', course_id: '1', name: 'Course 1', start_at: null, end_at: null},
  {id: '2', course_id: '1', name: 'Section A', start_at: null, end_at: null},
  {id: '3', course_id: '1', name: 'Section B', start_at: null, end_at: null},
  {id: '4', course_id: '1', name: 'Section C', start_at: null, end_at: null},
]

export const FILTERED_SECTIONS_DATA = [
  {id: '2', course_id: '1', name: 'Section A', start_at: null, end_at: null},
  {id: '3', course_id: '1', name: 'Section B', start_at: null, end_at: null},
  {id: '4', course_id: '1', name: 'Section C', start_at: null, end_at: null},
]

export const STUDENTS_DATA = [
  {id: '1', name: 'Ben', created_at: '2023-01-01', sortable_name: 'Ben', sis_user_id: 'ben001'},
  {
    id: '2',
    name: 'Peter',
    created_at: '2023-01-01',
    sortable_name: 'Peter',
    sis_user_id: 'peter002',
  },
  {
    id: '3',
    name: 'Grace',
    created_at: '2023-01-01',
    sortable_name: 'Grace',
    sis_user_id: 'grace003',
  },
  {
    id: '4',
    name: 'Secilia',
    created_at: '2023-01-01',
    sortable_name: 'Secilia',
    sis_user_id: 'random_id_8',
  },
]

export const FILTERED_STUDENTS_DATA = [
  {
    id: '4',
    name: 'Secilia',
    created_at: '2023-01-01',
    sortable_name: 'Secilia',
    sis_user_id: 'random_id_8',
  },
]

export const ASSIGNMENT_OVERRIDES_DATA = [
  {
    id: '1',
    title: 'Test',
    context_module_id: '2',
    students: [
      {
        id: '1',
        name: 'Ben',
      },
      {
        id: '2',
        name: 'Peter',
      },
    ],
  },
  {
    id: '2',
    title: 'Course',
    context_module_id: '2',
    course_section: {
      id: '2',
      name: 'Section A',
    },
  },
]
