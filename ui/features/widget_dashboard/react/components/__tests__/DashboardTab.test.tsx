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
import {render, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import DashboardTab from '../DashboardTab'

type Props = Record<string, never> // DashboardTab has no props

const mockCoursesData = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
        {
          course: {
            _id: '1',
            name: 'Introduction to Computer Science',
          },
        },
        {
          course: {
            _id: '2',
            name: 'Advanced Mathematics',
          },
        },
      ],
    },
  },
}

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

const server = setupServer(
  // Mock GraphQL queries used by CourseWorkSummaryWidget
  graphql.query('GetUserCourses', () => {
    return HttpResponse.json(mockCoursesData)
  }),
  graphql.query('GetUserCourseStatistics', () => {
    return HttpResponse.json(mockStatisticsData)
  }),
)

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {}

  return {...defaultProps, ...overrides}
}

const setup = (props?: Props, envOverrides = {}) => {
  // Set up Canvas ENV with current_user_id
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
    ...envOverrides,
  }

  // Create new QueryClient for each test
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
      <DashboardTab {...buildDefaultProps(props)} />
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

  it('should render widget grid with course work summary widget', async () => {
    const {getByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('widget-grid')).toBeInTheDocument()
      expect(getByTestId('widget-course-work-widget')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should display course work widget title', async () => {
    const {getByText, cleanup} = setup()

    await waitFor(() => {
      expect(getByText("Today's course work")).toBeInTheDocument()
    })

    cleanup()
  })

  it('should handle course statistics loading state', async () => {
    // Override server to return delayed response
    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockStatisticsData))
          }, 100)
        })
      }),
    )

    const {getByText, cleanup} = setup()

    await waitFor(() => {
      expect(getByText('Loading course work data...')).toBeInTheDocument()
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
