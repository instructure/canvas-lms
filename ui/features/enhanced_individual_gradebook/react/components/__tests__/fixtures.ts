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

import {MockedResponse} from '@apollo/react-testing'
import {GRADEBOOK_QUERY, GRADEBOOK_STUDENT_QUERY} from '../../../queries/Queries'

export const DEFAULT_ENV = {
  GRADEBOOK_OPTIONS: {
    active_grading_periods: [],
    context_id: '1',
    context_url: '/courses/1',
    userId: '10',
    course_settings: {},
  },
}

const GRADEBOOK_STUDENT_QUERY_MOCK_RESPONSE = {
  data: {
    course: {
      assignmentGroupsConnection: {
        nodes: [
          {
            id: '1',
            name: 'Assignments',
            state: 'available',
            position: 1,
            assignmentsConnection: {
              nodes: [
                {
                  id: '1',
                  name: 'Missing Assignment 1',
                },
              ],
            },
          },
        ],
      },
      enrollmentsConnection: {
        nodes: [
          {
            user: {
              id: '5',
              name: 'Test User 1',
              sortableName: 'User 1, Test',
            },
          },
        ],
      },
      submissionsConnection: {
        nodes: [],
      },
      sectionsConnection: {
        nodes: [],
      },
    },
  },
}

export const setupGraphqlMocks = (overrides: MockedResponse[] = []): MockedResponse[] => {
  return [
    {
      request: {
        query: GRADEBOOK_QUERY,
        variables: {courseId: '1'},
      },
      result: GRADEBOOK_STUDENT_QUERY_MOCK_RESPONSE,
    },
    {
      request: {
        query: GRADEBOOK_STUDENT_QUERY,
        variables: {
          courseId: '1',
          userIds: null,
        },
      },
      result: {
        data: null,
      },
    },
    ...overrides,
  ]
}
