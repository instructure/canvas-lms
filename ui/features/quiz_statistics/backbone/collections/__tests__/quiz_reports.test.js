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

import QuizReports from '../quiz_reports'

test('parses properly', function () {
  const fixture = {
    quiz_reports: [
      {
        id: '200',
        report_type: 'student_analysis',
        readable_type: 'Student Analysis',
        includes_all_versions: false,
        generatable: true,
        anonymous: false,
        url: 'http://localhost:3000/api/v1/courses/1/quizzes/8/reports/200',
        created_at: '2014-06-17T16:38:25Z',
        updated_at: '2014-06-17T16:38:25Z',
        links: {
          quiz: 'http://localhost:3000/api/v1/courses/1/quizzes/8',
        },
      },
      {
        id: '201',
        report_type: 'item_analysis',
        readable_type: 'Item Analysis',
        includes_all_versions: true,
        generatable: true,
        anonymous: false,
        url: 'http://localhost:3000/api/v1/courses/1/quizzes/8/reports/201',
        created_at: '2014-06-17T16:38:25Z',
        updated_at: '2014-06-17T16:38:25Z',
        links: {
          quiz: 'http://localhost:3000/api/v1/courses/1/quizzes/8',
        },
      },
    ],
  }

  const subject = new QuizReports()

  subject.add(fixture, {parse: true})

  expect(subject.length).toEqual(2)
  expect(subject.first().get('id')).toEqual('200')
  expect(subject.first().get('reportType')).toEqual('student_analysis')
})
