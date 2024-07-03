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

export const checkpointedAssignmentNoDueDates = {
  assignment: {
    id: '1',
    course_id: '1',
    name: 'Checkpoint Assignment',
    checkpoints: [
      {
        due_at: null,
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [],
        points_possible: 1,
        tag: 'reply_to_topic',
      },
      {
        due_at: null,
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [],
        points_possible: 1,
        tag: 'reply_to_entry',
      },
    ],
    discussion_topic: {
      reply_to_entry_required_count: 4,
    },
  },
}

export const checkpointedAssignmentWithDueDates = {
  assignment: {
    id: '1',
    course_id: '1',
    name: 'Checkpoint Assignment',
    checkpoints: [
      {
        due_at: '2024-06-02T17:43:13Z',
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [],
        points_possible: 1,
        tag: 'reply_to_topic',
      },
      {
        due_at: '2024-06-04T17:43:13Z',
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [],
        points_possible: 1,
        tag: 'reply_to_entry',
      },
    ],
    discussion_topic: {
      reply_to_entry_required_count: 4,
    },
  },
}

export const checkpointedAssignmentWithOverrides = {
  assignment: {
    id: '1',
    course_id: '1',
    name: 'Checkpoint Assignment',
    checkpoints: [
      {
        due_at: null,
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [
          {
            due_at: '2024-06-02T17:43:13Z',
            student_ids: ['1'],
            all_day: false,
            all_day_date: '',
            assignment_id: '1',
            id: '1',
            title: '',
            unassign_item: false,
          },
        ],
        points_possible: 1,
        tag: 'reply_to_topic',
      },
      {
        due_at: null,
        name: 'Checkpoint Assignment',
        only_visible_to_overrides: false,
        overrides: [
          {
            due_at: '2024-06-04T17:43:13Z',
            student_ids: ['1'],
            all_day: false,
            all_day_date: '',
            assignment_id: '1',
            id: '1',
            title: '',
            unassign_item: false,
          },
        ],
        points_possible: 1,
        tag: 'reply_to_entry',
      },
    ],
    discussion_topic: {
      reply_to_entry_required_count: 4,
    },
  },
}
