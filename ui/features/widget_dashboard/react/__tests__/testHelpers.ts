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

import {graphql, HttpResponse} from 'msw'
import {clearWidgetDashboardCache} from '../utils/persister'

// Export for use in tests - call this in beforeEach to prevent cache pollution
export {clearWidgetDashboardCache}

// Default mock data for GraphQL queries
const mockCoursesWithGradesResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
        {
          course: {
            _id: '1',
            name: 'Introduction to Computer Science',
            courseCode: 'CS101',
          },
          updatedAt: '2025-01-01T00:00:00Z',
          grades: {
            currentScore: 95,
            currentGrade: 'A',
            finalScore: 95,
            finalGrade: 'A',
            overrideScore: null,
            overrideGrade: null,
          },
        },
        {
          course: {
            _id: '2',
            name: 'Advanced Mathematics',
            courseCode: 'MATH301',
          },
          updatedAt: '2025-01-01T00:00:00Z',
          grades: {
            currentScore: 87,
            currentGrade: 'B+',
            finalScore: 87,
            finalGrade: 'B+',
            overrideScore: null,
            overrideGrade: null,
          },
        },
      ],
    },
  },
}

const mockCourseStatisticsResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
        {
          course: {
            _id: '123',
            name: 'Test Course',
            submissionStatistics: {
              submissionsDueCount: 5,
              missingSubmissionsCount: 2,
              submissionsSubmittedCount: 8,
            },
          },
        },
      ],
    },
  },
}

const mockCoursesWithGradesConnectionResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: [
          {
            course: {
              _id: '1',
              name: 'Introduction to Computer Science',
              courseCode: 'CS101',
            },
            updatedAt: '2025-01-01T00:00:00Z',
            grades: {
              currentScore: 95,
              currentGrade: 'A',
              finalScore: 95,
              finalGrade: 'A',
              overrideScore: null,
              overrideGrade: null,
            },
          },
          {
            course: {
              _id: '2',
              name: 'Advanced Mathematics',
              courseCode: 'MATH301',
            },
            updatedAt: '2025-01-01T00:00:00Z',
            grades: {
              currentScore: 87,
              currentGrade: 'B+',
              finalScore: 87,
              finalGrade: 'B+',
              overrideScore: null,
              overrideGrade: null,
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
}

// Common GraphQL handlers that can be used across tests
export const defaultGraphQLHandlers = [
  // Handle GetUserCoursesWithGrades query
  graphql.query('GetUserCoursesWithGrades', () => {
    return HttpResponse.json(mockCoursesWithGradesResponse)
  }),

  // Handle GetUserCoursesWithGradesConnection query
  graphql.query('GetUserCoursesWithGradesConnection', () => {
    return HttpResponse.json(mockCoursesWithGradesConnectionResponse)
  }),

  // Handle GetUserCourseStatistics query
  graphql.query('GetUserCourseStatistics', () => {
    return HttpResponse.json(mockCourseStatisticsResponse)
  }),

  // Handle any other common queries that might be used
  graphql.query('GetAnnouncements', () => {
    return HttpResponse.json({
      data: {
        announcements: [],
      },
    })
  }),

  // Handle GetAccountNotifications query
  graphql.query('GetAccountNotifications', () => {
    return HttpResponse.json({
      data: {
        accountNotifications: [],
      },
    })
  }),

  // Handle GetDashboardNotifications query
  graphql.query('GetDashboardNotifications', () => {
    return HttpResponse.json({
      data: {
        accountNotifications: [],
        enrollmentInvitations: [],
      },
    })
  }),

  // Handle GetCourseInstructorsPaginated query
  graphql.query('GetCourseInstructorsPaginated', () => {
    return HttpResponse.json({
      data: {
        courseInstructorsConnection: {
          nodes: [],
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            startCursor: null,
            endCursor: null,
          },
        },
      },
    })
  }),

  // Handle UpdateWidgetDashboardConfig mutation
  graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateWidgetDashboardConfig: {
          widgetId: variables.widgetId,
          filters: variables.filters,
          errors: null,
        },
      },
    })
  }),
]

// Helper to create empty responses
export const createEmptyCoursesResponse = () => ({
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [],
    },
  },
})

// Helper to create error responses
export const createErrorResponse = (message: string) => ({
  errors: [{message}],
})
