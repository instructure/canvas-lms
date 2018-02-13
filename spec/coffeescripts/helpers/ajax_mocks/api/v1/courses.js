/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import $ from 'support/jquery.mockjax'

export default $.mockjax({
  url: /\/api\/v1\/courses\/\d+(\?.+)?$/,
  responseText: [
    {
      name: "teacher's test course",
      id: 1,
      enrollments: [{type: 'teacher'}],
      course_code: 'RY 101',
      sis_course_id: null,
      calendar: {
        ics:
          'http://example.com/feeds/calendars/course_e3b41bfc0e6665062b8d442e0b7096f49d1f3859.ics'
      }
    },
    {
      name: 'My Course',
      id: 8,
      enrollments: [{type: 'ta'}],
      course_code: 'Course-101',
      sis_course_id: null,
      calendar: {
        ics:
          'http://example.com/feeds/calendars/course_KdkLMSWISSmVHhX5T5hxjNE1lUDLF0zXfojIUISE.ics'
      }
    },
    {
      name: 'corse i am a student in',
      id: 9,
      enrollments: [{type: 'student'}],
      course_code: 'criasi',
      sis_course_id: null,
      calendar: {
        ics:
          'http://example.com/feeds/calendars/course_PVeprcyWyJnk4evwazeGrDGBcTdTFCm2WZVRTlyE.ics'
      }
    }
  ]
})
