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

import React from 'react'
import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import DashboardTab from '../DashboardTab'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'
import {WidgetDashboardProvider} from '../../hooks/useWidgetDashboardContext'
import {WidgetDashboardEditProvider} from '../../hooks/useWidgetDashboardEdit'
type Props = Record<string, never> // DashboardTab has no props

const mockStatisticsData = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
        {
          course: {
            _id: '1',
            name: 'Introduction to Computer Science',
            submissionStatistics: {
              submissionsDueCount: 3,
              missingSubmissionsCount: 1,
              submissionsSubmittedCount: 5,
            },
          },
        },
        {
          course: {
            _id: '2',
            name: 'Advanced Mathematics',
            submissionStatistics: {
              submissionsDueCount: 2,
              missingSubmissionsCount: 0,
              submissionsSubmittedCount: 3,
            },
          },
        },
      ],
    },
  },
}

let queryClient: QueryClient

const mockAnnouncementsData = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [],
    },
  },
}

const server = setupServer(
  // Handle GetUserCoursesWithGradesConnection query (used by useUserCourses)
  graphql.query('GetUserCoursesWithGradesConnection', () => {
    return HttpResponse.json({
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
    })
  }),
  // Override specific queries with local mock data
  graphql.query('GetUserCourseStatistics', () => {
    return HttpResponse.json(mockStatisticsData)
  }),
  // Mock GraphQL queries used by AnnouncementsWidget
  graphql.query('GetUserAnnouncements', () => {
    return HttpResponse.json(mockAnnouncementsData)
  }),
  // Handle GetUserCourseWork query
  graphql.query('GetUserCourseWork', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '123',
          enrollments: [],
        },
      },
    })
  }),
  // Handle any other common queries that might be used
  graphql.query('GetAnnouncements', () => {
    return HttpResponse.json({
      data: {
        announcements: [],
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
)

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {}

  return {...defaultProps, ...overrides}
}

const setup = (props?: Props, envOverrides = {}, dashboardFeatures = {}) => {
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
    ...envOverrides,
  }

  queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider dashboardFeatures={dashboardFeatures}>
        <WidgetDashboardEditProvider>
          <DashboardTab {...buildDefaultProps(props)} />
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )

  return {
    ...result,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

describe('DashboardTab', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    clearWidgetDashboardCache()
  })

  afterEach(() => {
    server.resetHandlers()
    if (queryClient) {
      queryClient.clear()
    }
  })

  afterAll(() => {
    server.close()
  })

  it('should render the dashboard tab content', async () => {
    const {getByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should render widget columns with course work widget', async () => {
    const {getByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('widget-columns')).toBeInTheDocument()
      expect(getByTestId('widget-course-work-combined-widget')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should display course work widget title', async () => {
    const {getByText, cleanup} = setup()

    await waitFor(() => {
      expect(getByText('Course work')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should display course work statistics when loaded', async () => {
    const {getByText, cleanup} = setup()

    await waitFor(() => {
      expect(getByText('5')).toBeInTheDocument() // Due count (3+2 from both courses)
      expect(getByText('1')).toBeInTheDocument() // Missing count (1+0 from both courses)
      expect(getByText('8')).toBeInTheDocument() // Submitted count (5+3 from both courses)
    })

    expect(getByText('Due')).toBeInTheDocument()
    expect(getByText('Missing')).toBeInTheDocument()
    expect(getByText('Submitted')).toBeInTheDocument()

    cleanup()
  })

  it('renders properly with default props', async () => {
    const {container, cleanup} = setup()

    await waitFor(() => {
      expect(container).not.toBeEmptyDOMElement()
    })

    cleanup()
  })

  it('should handle missing current_user_id gracefully', async () => {
    const {getByTestId, cleanup} = setup({}, {current_user_id: undefined})

    await waitFor(() => {
      expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
    })

    cleanup()
  })
})
