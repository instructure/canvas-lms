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
 *
 */

import moment from 'moment-timezone'

export const GRADING_PERIODS = [
  {
    id: '1',
    title: 'Spring 2020',
    start_date: '2020-01-01T07:00:00Z',
    end_date: '2020-07-01T06:59:59Z',
    workflow_state: 'active',
  },
  {
    id: '2',
    title: 'Fall 2020',
    start_date: '2020-07-01T07:00:00Z',
    end_date: '2021-01-01T06:59:59Z',
    workflow_state: 'active',
  },
  {
    id: '3',
    title: 'Fall 2019',
    start_date: '2019-07-01T07:00:00Z',
    end_date: '2020-01-01T06:59:59Z',
    workflow_state: 'deleted',
  },
]

export const MOCK_ASSIGNMENTS = [
  {
    context_code: 'course_1',
    context_color: null,
    context_name: 'Algebra 2',
    html_url: 'http://localhost:3000/courses/30/assignments/175',
    id: 'assignment_175',
    important_dates: true,
    start_at: '2021-07-02T13:59:59Z',
    title: 'Math HW',
    type: 'assignment',
    assignment: {
      due_at: '2021-07-02T13:59:59Z', // 7:59am MT, 7:44pm Kathmandu
      submission_types: ['online_text_entry', 'online_url', 'media_recording', 'online_upload'],
    },
  },
  {
    context_code: 'course_3',
    context_color: '#CCCCCC',
    context_name: 'History',
    html_url: 'http://localhost:3000/courses/31/assignments/176',
    id: 'assignment_176',
    important_dates: true,
    start_at: '2021-07-04T05:59:59Z',
    title: 'History Discussion',
    type: 'assignment',
    assignment: {
      due_at: '2021-07-04T11:30:00Z', // 5:30am MT, 5:15pm Kathmandu
      submission_types: ['discussion_topic'],
    },
  },
  {
    context_code: 'course_3',
    context_color: '#CCCCCC',
    context_name: 'History',
    html_url: 'http://localhost:3000/courses/31/assignments/177',
    id: 'assignment_177',
    important_dates: true,
    start_at: '2021-07-04T22:00:00Z',
    title: 'History Exam',
    type: 'assignment',
    assignment: {
      due_at: '2021-07-04T22:00:00Z', // 4pm MT, 3:45am Jul 5 Kathmandu
      submission_types: ['online_quiz'],
    },
  },
]

export const MOCK_OBSERVEE_ASSIGNMENTS = [
  {
    context_code: 'course_31',
    context_color: null,
    context_name: 'Math',
    html_url: 'http://localhost:3000/courses/31/assignments/111',
    id: 'assignment_111',
    important_dates: true,
    start_at: '2021-10-02T13:59:59Z',
    title: 'Number theory',
    type: 'assignment',
    assignment: {
      due_at: '2021-10-02T13:59:59Z', // 7:59am MT, 7:44pm Kathmandu
      submission_types: ['online_text_entry', 'online_url', 'media_recording', 'online_upload'],
    },
  },
  {
    context_code: 'course_32',
    context_color: '#CCCCCC',
    context_name: 'Physics',
    html_url: 'http://localhost:3000/courses/32/assignments/200',
    id: 'assignment_200',
    important_dates: true,
    start_at: '2021-010-04T05:59:59Z',
    title: 'Dynamics',
    type: 'assignment',
    assignment: {
      due_at: '2021-10-04T11:30:00Z', // 5:30am MT, 5:15pm Kathmandu
      submission_types: ['online_quiz'],
    },
  },
]

export const MOCK_CARDS = [
  {
    id: '1',
    assetString: 'course_1',
    href: '/courses/1',
    shortName: 'Economics 101',
    originalName: 'UGLY-SIS-ECON-101',
    color: 'yellow',
    courseCode: 'ECON-001',
    enrollmentState: 'active',
    isHomeroom: false,
    isK5Subject: true,
    canManage: true,
    canReadAnnouncements: true,
    published: true,
  },
  {
    id: '2',
    assetString: 'course_2',
    href: '/courses/2',
    shortName: 'Home Room',
    originalName: 'UGLY-SIS-HOMEROOM-007',
    color: 'blue',
    courseCode: 'HOME-001',
    enrollmentState: 'active',
    isHomeroom: true,
    isK5Subject: false,
    canManage: true,
    canReadAnnouncements: true,
    published: false,
  },
  {
    id: '3',
    assetString: 'course_3',
    href: '/courses/3',
    shortName: 'The Maths',
    originalName: 'UGLY-SIS-BEG-ALG-101',
    color: 'red',
    courseCode: 'DA-MATHS',
    enrollmentState: 'invited',
    isHomeroom: false,
    isK5Subject: true,
    canManage: true,
    canReadAnnouncements: true,
    published: true,
  },
]

export const MOCK_CARDS_2 = [
  {
    id: '23',
    assetString: 'course_23',
    href: '/courses/23',
    shortName: 'Economics 203',
    originalName: 'UGLY-SIS-ECON-203',
    color: 'yellow',
    courseCode: 'ECON-203',
    enrollmentState: 'active',
    isHomeroom: false,
    isK5Subject: true,
    canManage: true,
    published: true,
  },
]

export const MOCK_EVENTS = [
  {
    context_color: '#CCCCCC',
    context_name: 'History',
    html_url: 'http://localhost:3000/calendar?event_id=99&include_contexts=course_30',
    id: '99',
    important_dates: true,
    start_at: '2021-06-30T07:00:00Z', // 1am MT, 12:45pm Kathmandu
    title: 'Morning Yoga',
    type: 'event',
  },
]

export const MOCK_ACCOUNT_CALENDAR_EVENT = {
  context_color: null,
  context_name: 'CSU',
  html_url: 'http://localhost:3000/calendar?event_id=45&include_contexts=account_1',
  id: '45',
  important_dates: true,
  start_at: '2021-06-29T07:00:00Z',
  title: 'Football Game',
  type: 'event',
}

export const MOCK_OBSERVEE_EVENTS = [
  {
    context_color: '#CCCCCC',
    context_name: 'Math',
    html_url: 'http://localhost:3000/calendar?event_id=99&include_contexts=course_31',
    id: '100',
    important_dates: true,
    start_at: '2021-10-30T07:00:00Z', // 1am MT, 12:45pm Kathmandu
    title: 'First Quiz',
    type: 'event',
  },
]

export const MOCK_PLANNER_ITEM = [
  {
    context_name: 'Course2',
    context_type: 'Course',
    course_id: '1',
    html_url: '/courses/2/assignments/15',
    new_activity: false,
    plannable: {
      created_at: '2021-03-16T17:17:17Z',
      due_at: moment()?.toISOString(),
      id: '15',
      points_possible: 10,
      title: 'Assignment 15',
      updated_at: '2021-03-16T17:31:52Z',
    },
    plannable_date: moment()?.toISOString(),
    plannable_id: '15',
    plannable_type: 'assignment',
    planner_override: null,
    submissions: {
      excused: false,
      graded: false,
      has_feedback: false,
      late: false,
      missing: true,
      needs_grading: false,
      redo_request: false,
      submitted: false,
    },
  },
]

export const IMPORTANT_DATES_CONTEXTS = [
  {assetString: 'course_1', name: 'Economics 101', color: 'yellow'},
  {assetString: 'course_2', name: 'Home Room', color: 'blue'},
  {assetString: 'course_3', name: 'The Maths', color: 'red'},
]
