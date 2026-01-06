/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import type {Course, Teacher, Term} from '../types/course'

export const createMockTeacher = (overrides?: Partial<Teacher>): Teacher => ({
  id: '10',
  display_name: 'John Doe',
  html_url: '/users/10',
  avatar_image_url: 'https://example.com/avatar.jpg',
  ...overrides,
})

export const createMockTerm = (overrides?: Partial<Term>): Term => ({
  name: 'Fall 2026',
  ...overrides,
})

export const createMockCourse = (overrides?: Partial<Course>): Course => ({
  id: '1',
  name: 'Introduction to Testing',
  workflow_state: 'available',
  sis_course_id: 'SIS-101',
  total_students: 25,
  teachers: [
    createMockTeacher({id: '10', display_name: 'John Doe', html_url: '/users/10'}),
    createMockTeacher({id: '11', display_name: 'Jane Smith', html_url: '/users/11'}),
  ],
  term: createMockTerm(),
  subaccount_id: '5',
  subaccount_name: 'College of Engineering',
  ...overrides,
})

export const createMockCourses = (count: number, overrides?: Partial<Course>): Course[] =>
  Array.from({length: count}, (_, i) =>
    createMockCourse({
      id: String(i),
      name: `Course ${i}`,
      ...overrides,
    }),
  )
