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

export const GRADING_PERIODS = [
  {
    id: '1',
    title: 'Spring 2020',
    start_date: '2020-01-01T07:00:00Z',
    end_date: '2020-07-01T06:59:59Z',
    workflow_state: 'active'
  },
  {
    id: '2',
    title: 'Fall 2020',
    start_date: '2020-07-01T07:00:00Z',
    end_date: '2021-01-01T06:59:59Z',
    workflow_state: 'active'
  },
  {
    id: '3',
    title: 'Fall 2019',
    start_date: '2019-07-01T07:00:00Z',
    end_date: '2020-01-01T06:59:59Z',
    workflow_state: 'deleted'
  }
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
      submission_types: ['online_text_entry', 'online_url', 'media_recording', 'online_upload']
    }
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
      submission_types: ['discussion_topic']
    }
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
      submission_types: ['online_quiz']
    }
  }
]

export const MOCK_CARDS = [
  {
    id: '1',
    assetString: 'course_1',
    href: '/courses/1',
    shortName: 'Econ 101',
    originalName: 'Economics 101',
    color: 'yellow',
    courseCode: 'ECON-001',
    enrollmentState: 'active',
    isHomeroom: false,
    isK5Subject: true,
    canManage: true,
    published: true
  },
  {
    id: '2',
    assetString: 'course_2',
    href: '/courses/2',
    shortName: 'Homeroom1',
    originalName: 'Home Room',
    color: 'blue',
    courseCode: 'HOME-001',
    enrollmentState: 'active',
    isHomeroom: true,
    isK5Subject: false,
    canManage: true,
    published: false
  },
  {
    id: '3',
    assetString: 'course_3',
    href: '/courses/3',
    originalName: 'The Maths',
    color: 'red',
    courseCode: 'DA-MATHS',
    enrollmentState: 'invited',
    isHomeroom: false,
    isK5Subject: true,
    canManage: true,
    published: true
  }
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
    type: 'event'
  }
]
