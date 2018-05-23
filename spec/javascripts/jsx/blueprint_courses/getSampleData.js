/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

export default function getSampleData () {
  return {
    terms: [
      { id: '1', name: 'Term One' },
      { id: '2', name: 'Term Two' },
    ],
    subAccounts: [
      { id: '1', name: 'Account One' },
      { id: '2', name: 'Account Two' },
    ],
    childCourse: {
      id: '1',
      enrollment_term_id: '1',
      name: 'Course 1',
    },
    masterCourse: {
      id: '2',
      enrollment_term_id: '1',
      name: 'Course 2',
    },
    courses: [
      {
        id: '1',
        name: 'Course One',
        course_code: 'course_1',
        term: {
          id: '1',
          name: 'Term One',
        },
        teachers: [{
          display_name: 'Teacher One',
        }],
        sis_course_id: '1001',
      },
      {
        id: '2',
        name: 'Course Two',
        course_code: 'course_2',
        term: {
          id: '2',
          name: 'Term Two',
        },
        teachers: [{
          display_name: 'Teacher Two',
        }],
        sis_course_id: '1001',
      }
    ],
    history: [
      {
        id: '2',
        workflow_state: 'completed',
        created_at: '2013-08-28T23:59:00-06:00',
        changes: [
          {
            asset_id: '2',
            asset_type: 'quiz',
            asset_name: 'Chapter 5 Quiz',
            change_type: 'updated',
            html_url: 'http://localhost:3000/courses/3/quizzes/2',
            exceptions: [
              {
                course_id: '1',
                conflicting_changes: ['points'],
                name: 'Course 1',
                term: { name: 'Default Term' },
              },
              {
                course_id: '5',
                conflicting_changes: ['content'],
                name: 'Course 5',
                term: { name: 'Default Term' },
              },
              {
                course_id: '56',
                conflicting_changes: ['deleted'],
                name: 'Course 56',
                term: { name: 'Default Term' },
              }
            ],
          }
        ],
      },
    ],
    unsyncedChanges: [
      {
        asset_id: '22',
        asset_type: 'assignment',
        asset_name: 'Another Discussion',
        change_type: 'deleted',
        html_url: '/courses/4/assignments/22',
        locked: false
      },
      {
        asset_id: '22',
        asset_type: 'attachment',
        asset_name: 'Bulldog.png',
        change_type: 'updated',
        html_url: '/courses/4/files/96',
        locked: true
      },
      {
        asset_id: 'page-1',
        asset_type: 'wiki_page',
        asset_name: 'Page 1',
        change_type: 'created',
        html_url: '/4/pages/page-1',
        locked: false
      }
    ]
  }
};
