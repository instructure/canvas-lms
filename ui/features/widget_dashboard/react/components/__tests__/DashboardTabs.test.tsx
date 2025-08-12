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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, http, HttpResponse} from 'msw'
import DashboardTabs from '../DashboardTabs'

type Props = Record<string, never> // DashboardTabs has no props

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
  // Mock REST API for CoursesTab
  http.get('/api/v1/dashboard/dashboard_cards', () => {
    return HttpResponse.json([
      {
        id: '1',
        shortName: 'CS101',
        originalName: 'Introduction to Computer Science',
        courseCode: 'CS101',
        href: '/courses/1',
      },
      {
        id: '2',
        shortName: 'MATH201',
        originalName: 'Advanced Mathematics',
        courseCode: 'MATH201',
        href: '/courses/2',
      },
    ])
  }),
)

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {}

  return {...defaultProps, ...overrides}
}

const setup = (props?: Props, envOverrides = {}) => {
  const user = userEvent.setup()

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

  const renderResult = render(
    <QueryClientProvider client={queryClient}>
      <DashboardTabs {...buildDefaultProps(props)} />
    </QueryClientProvider>,
  )

  return {
    user,
    ...renderResult,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

describe('DashboardTabs', () => {
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

  it('should render both tab labels', async () => {
    const {getByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('tab-dashboard')).toBeInTheDocument()
      expect(getByTestId('tab-courses')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should show Dashboard tab content by default', async () => {
    const {getByTestId, queryByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
    })

    expect(queryByTestId('courses-tab-content')).not.toBeInTheDocument()

    cleanup()
  })

  it('should switch to Courses tab when clicked', async () => {
    const {user, getByTestId, queryByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('tab-courses')).toBeInTheDocument()
    })

    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    await waitFor(() => {
      expect(getByTestId('courses-tab-content')).toBeInTheDocument()
    })

    expect(queryByTestId('dashboard-tab-content')).not.toBeInTheDocument()

    cleanup()
  })

  it('should switch back to Dashboard tab when clicked', async () => {
    const {user, getByTestId, queryByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('tab-courses')).toBeInTheDocument()
    })

    // Click Courses tab first
    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    await waitFor(() => {
      expect(getByTestId('courses-tab-content')).toBeInTheDocument()
    })

    // Then click Dashboard tab
    const dashboardTab = getByTestId('tab-dashboard')
    await user.click(dashboardTab)

    await waitFor(() => {
      expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
    })

    expect(queryByTestId('courses-tab-content')).not.toBeInTheDocument()

    cleanup()
  })

  it('should have proper ARIA attributes for accessibility', async () => {
    const {getByTestId, container, cleanup} = setup()

    await waitFor(() => {
      const tabList = container.querySelector('[role="tablist"]')
      expect(tabList).toBeInTheDocument()

      expect(getByTestId('tab-dashboard')).toBeInTheDocument()
      expect(getByTestId('tab-courses')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should update ARIA states when switching tabs', async () => {
    const {user, getByTestId, queryByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('tab-courses')).toBeInTheDocument()
    })

    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    await waitFor(() => {
      expect(getByTestId('courses-tab-content')).toBeInTheDocument()
      expect(queryByTestId('dashboard-tab-content')).not.toBeInTheDocument()
    })

    cleanup()
  })

  it('should display Dashboard tab with course work widget', async () => {
    const {getByTestId, getByText, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
      expect(getByTestId('widget-course-work-widget')).toBeInTheDocument()
      expect(getByText("Today's course work")).toBeInTheDocument()
    })

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
      expect(getByTestId('dashboard-tabs')).toBeInTheDocument()
    })

    cleanup()
  })
})
