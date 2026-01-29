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

import type {PlannerItem} from '../../types'

const tomorrow = new Date()
tomorrow.setDate(tomorrow.getDate() + 1)

const nextWeek = new Date()
nextWeek.setDate(nextWeek.getDate() + 7)

const baseMockPlannerItems: PlannerItem[] = [
  {
    plannable_id: '1',
    plannable_type: 'assignment',
    plannable_date: tomorrow.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'Biology 101',
    course_id: '1',
    html_url: '/courses/1/assignments/1',
    plannable: {
      id: '1',
      title: 'Lab Report: Cell Structure',
      due_at: tomorrow.toISOString(),
      points_possible: 100,
      assignment_id: '1',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: {
      submitted: false,
      excused: false,
      graded: false,
      late: false,
      missing: false,
      needs_grading: false,
      has_feedback: false,
      redo_request: false,
    },
    planner_override: null,
  },
  {
    plannable_id: '2',
    plannable_type: 'quiz',
    plannable_date: tomorrow.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'Chemistry 201',
    course_id: '2',
    html_url: '/courses/2/quizzes/2',
    plannable: {
      id: '2',
      title: 'Chapter 5 Quiz',
      due_at: tomorrow.toISOString(),
      points_possible: 50,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '3',
    plannable_type: 'discussion_topic',
    plannable_date: nextWeek.toISOString(),
    new_activity: true,
    context_type: 'Course',
    context_name: 'English 301',
    course_id: '3',
    html_url: '/courses/3/discussion_topics/3',
    plannable: {
      id: '3',
      title: 'Discuss: Shakespeare Analysis',
      due_at: nextWeek.toISOString(),
      points_possible: 25,
      unread_count: 3,
      read_state: 'unread',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: {
      submitted: false,
      excused: false,
      graded: false,
      late: false,
      missing: false,
      needs_grading: false,
      has_feedback: false,
      redo_request: false,
    },
    planner_override: null,
  },
  {
    plannable_id: '4',
    plannable_type: 'announcement',
    plannable_date: '2025-01-01T00:00:00Z',
    new_activity: true,
    context_type: 'Course',
    context_name: 'Math 101',
    course_id: '4',
    html_url: '/courses/4/discussion_topics/4',
    plannable: {
      id: '4',
      title: 'Important: Exam Schedule',
      unread_count: 0,
      read_state: 'read',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '5',
    plannable_type: 'wiki_page',
    plannable_date: nextWeek.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'History 201',
    course_id: '5',
    html_url: '/courses/5/pages/5',
    plannable: {
      id: '5',
      title: 'Read: World War II Overview',
      todo_date: nextWeek.toISOString(),
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '6',
    plannable_type: 'calendar_event',
    plannable_date: nextWeek.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'Physics 101',
    course_id: '6',
    html_url: '/calendar?event_id=6',
    plannable: {
      id: '6',
      title: 'Office Hours with Dr. Smith',
      start_at: nextWeek.toISOString(),
      location_name: 'Room 204',
      all_day: false,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '7',
    plannable_type: 'planner_note',
    plannable_date: tomorrow.toISOString(),
    new_activity: false,
    html_url: '/api/v1/planner_notes/7',
    plannable: {
      id: '7',
      title: 'Buy textbook for Biology',
      todo_date: tomorrow.toISOString(),
      details: 'Need to purchase from bookstore',
      user_id: 123,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '8',
    plannable_type: 'assessment_request',
    plannable_date: nextWeek.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'Art 301',
    course_id: '8',
    html_url: '/courses/8/assignments/8/submissions/1',
    plannable: {
      id: '8',
      title: 'Review: Student Portfolio',
      todo_date: nextWeek.toISOString(),
      workflow_state: 'assigned',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: false,
    planner_override: null,
  },
  {
    plannable_id: '9',
    plannable_type: 'discussion_topic_checkpoint',
    plannable_date: nextWeek.toISOString(),
    new_activity: false,
    context_type: 'Course',
    context_name: 'Psychology 201',
    course_id: '9',
    html_url: '/courses/9/assignments/9',
    plannable: {
      id: '9',
      title: 'Discussion Checkpoint: Reply Required',
      due_at: nextWeek.toISOString(),
      points_possible: 10,
      sub_assignment_tag: 'reply_to_topic',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    submissions: {
      submitted: false,
      excused: false,
      graded: false,
      late: false,
      missing: false,
      needs_grading: false,
      has_feedback: false,
      redo_request: false,
    },
    planner_override: null,
    details: {
      reply_to_entry_required_count: 2,
    },
  },
]

export const mockPlannerItems: PlannerItem[] = [
  ...baseMockPlannerItems,
  ...Array.from({length: 20}, (_, i) => ({
    ...baseMockPlannerItems[0],
    plannable_id: `extra-${i + 10}`,
    plannable: {
      ...baseMockPlannerItems[0].plannable,
      id: `extra-${i + 10}`,
      title: `Extra Assignment ${i + 10}`,
    },
  })),
]
