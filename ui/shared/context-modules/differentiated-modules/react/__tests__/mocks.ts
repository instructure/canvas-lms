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

export const DIFFERENTIATION_TAGS_DATA = [
  {id: '1', course_id: '1', name: 'Tag 1', group_category_id: '1', non_collaborative: true, group_category: {id: '1', name: 'Differentiation Tags'}},
  {id: '2', course_id: '1', name: 'Tag 2', group_category_id: '1', non_collaborative: true, group_category: {id: '1', name: 'Differentiation Tags'}},
  {id: '3', course_id: '1', name: 'Tag 3', group_category_id: '1', non_collaborative: true, group_category: {id: '1', name: 'Differentiation Tags'}},
]

export const STUDENTS_DATA = [
  {
    id: 'student-1',
    value: 'Ben',
    sisID: 'ben001',
    group: 'Students',
  },
  {
    id: 'student-2',
    value: 'Peter',
    sisID: 'peter002',
    group: 'Students',
  },
  {
    id: 'student-3',
    value: 'Grace',
    sisID: 'grace003',
    group: 'Students',
  },
  {
    id: 'student-4',
    value: 'Secilia',
    sisID: 'random_id_8',
    group: 'Students',
  },
]

export const FILTERED_STUDENTS_DATA = [
  {
    id: '4',
    value: 'Secilia',
    sisID: 'random_id_8',
    group: 'Students',
  },
]

export const FIRST_GROUP_CATEGORY_DATA = [
  {id: '1', course_id: '1', name: 'Group 1'},
  {id: '2', course_id: '1', name: 'Group 2'},
  {id: '3', course_id: '1', name: 'Group 3'},
]

export const SECOND_GROUP_CATEGORY_DATA = [
  {id: '5', course_id: '1', name: 'Group 5'},
  {id: '6', course_id: '1', name: 'Group 6'},
  {id: '7', course_id: '1', name: 'Group 7'},
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
  {
    id: '3',
    title: 'Differentiation Tag',
    context_module_id: '2',
    group: {
      id: '1',
      name: 'Tag 1',
    },
  },
]

export const ADHOC_WITHOUT_STUDENTS = {
  id: '23',
  due_at: '2023-10-05T12:00:00Z',
  unlock_at: '2023-10-01T12:00:00Z',
  lock_at: '2023-11-01T12:00:00Z',
  only_visible_to_overrides: false,
  visible_to_everyone: false,
  overrides: [
    {
      id: '1',
      assignment_id: '23',
      title: 'No Title',
      unassign_item: false,
      student_ids: [],
      students: [],
    },
    {
      id: '2',
      assignment_id: '23',
      title: 'Section A',
      due_at: '2023-10-02T12:00:00Z',
      all_day: false,
      all_day_date: '2023-10-02',
      unlock_at: null,
      lock_at: null,
      course_section_id: '4',
    },
  ],
}
