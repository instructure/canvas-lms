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

export const MOCK_TODOS = [
  {
    assignment: {
      id: '11',
      due_at: '2021-06-22T23:59:59Z',
      name: 'Plant a plant',
      points_possible: 15
    },
    context_id: '5',
    context_type: 'Course',
    context_name: 'Horticulture',
    html_url: '/courses/5/gradebook/speed_grader?assignment_id=11',
    ignore: '/api/v1/users/self/todo/assignment_11/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_11/grading?permanent=1',
    needs_grading_count: 3
  },
  {
    assignment: {
      id: '12',
      due_at: '2021-07-15T23:59:59Z',
      name: 'Dream a dream',
      points_possible: 5
    },
    context_id: '2',
    context_type: 'Course',
    context_name: 'Oneirology',
    html_url: '/courses/2/gradebook/speed_grader?assignment_id=12',
    ignore: '/api/v1/users/self/todo/assignment_12/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_12/grading?permanent=1',
    needs_grading_count: 1
  }
]
