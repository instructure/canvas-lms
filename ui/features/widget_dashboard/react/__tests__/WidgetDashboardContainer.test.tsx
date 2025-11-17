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
import {graphql, http, HttpResponse} from 'msw'
import WidgetDashboardContainer from '../WidgetDashboardContainer'
import {WidgetDashboardProvider} from '../hooks/useWidgetDashboardContext'
import {WidgetDashboardEditProvider} from '../hooks/useWidgetDashboardEdit'
import {WidgetLayoutProvider} from '../hooks/useWidgetLayout'
import {ResponsiveProvider} from '../hooks/useResponsiveContext'
import {defaultGraphQLHandlers, clearWidgetDashboardCache} from './testHelpers'

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
      ],
    },
  },
}

const mockAnnouncementsData = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [],
    },
  },
}

let queryClient: QueryClient

const server = setupServer(
  ...defaultGraphQLHandlers,
  graphql.query('GetUserCourseStatistics', () => {
    return HttpResponse.json(mockStatisticsData)
  }),
  graphql.query('GetUserCourseWork', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '123',
          enrollments: [
            {
              course: {
                _id: '123',
                name: 'Test Course',
                assignmentsConnection: {
                  nodes: [],
                },
              },
            },
          ],
        },
      },
    })
  }),
  graphql.query('GetUserAnnouncements', () => {
    return HttpResponse.json(mockAnnouncementsData)
  }),
  http.get('/api/v1/dashboard/dashboard_cards', () => {
    return HttpResponse.json([])
  }),
  http.get('/api/v1/planner/items', () => {
    return HttpResponse.json([])
  }),
)

const setup = (contextProps = {}, envOverrides = {}) => {
  // Set up Canvas ENV
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
      <WidgetDashboardProvider {...contextProps}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>
            <ResponsiveProvider matches={['desktop']}>
              <WidgetDashboardContainer />
            </ResponsiveProvider>
          </WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )

  return {
    ...renderResult,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

describe('WidgetDashboardContainer', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    window.ENV = {current_user_id: '123'} as any
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

  it('should render dashboard heading', async () => {
    const {getByTestId, cleanup} = setup()

    expect(getByTestId('dashboard-heading')).toBeInTheDocument()

    cleanup()
  })

  it('should render DashboardTabs component', async () => {
    const {getByTestId, cleanup} = setup()

    await waitFor(() => {
      expect(getByTestId('dashboard-tabs')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should not render ObserverOptions when no observed users', () => {
    const {queryByTestId, cleanup} = setup({
      observedUsersList: [],
      currentUser: {
        id: '123',
        display_name: 'Test User',
        avatar_image_url: 'test.jpg',
      },
    })

    expect(queryByTestId('observed-student-dropdown')).not.toBeInTheDocument()

    cleanup()
  })

  it('should not render ObserverOptions when currentUser is null', () => {
    const {queryByTestId, cleanup} = setup({
      observedUsersList: [
        {id: '1', name: 'Student 1'},
        {id: '2', name: 'Student 2'},
      ],
      currentUser: null,
    })

    expect(queryByTestId('observed-student-dropdown')).not.toBeInTheDocument()

    cleanup()
  })

  it('should render ObserverOptions when observed users and currentUser exist', () => {
    const {getByTestId, cleanup} = setup({
      observedUsersList: [
        {id: '1', name: 'Student 1', avatar_url: 'student1.jpg'},
        {id: '2', name: 'Student 2'},
      ],
      currentUser: {
        id: '123',
        display_name: 'Observer User',
        avatar_image_url: 'observer.jpg',
      },
      canAddObservee: true,
      currentUserRoles: ['observer', 'user'],
    })

    // Multiple users should render dropdown
    expect(getByTestId('observed-student-dropdown')).toBeInTheDocument()

    cleanup()
  })

  it('should pass correct props to ObserverOptions', () => {
    const observedUsersList = [
      {id: '1', name: 'Student 1', avatar_url: 'student1.jpg'},
      {id: '2', name: 'Student 2'},
    ]
    const currentUser = {
      id: '123',
      display_name: 'Observer User',
      avatar_image_url: 'observer.jpg',
    }
    const currentUserRoles = ['observer']

    const {getByTestId, cleanup} = setup({
      observedUsersList,
      currentUser,
      canAddObservee: false,
      currentUserRoles,
    })

    // Multiple users should render dropdown
    const dropdown = getByTestId('observed-student-dropdown')
    expect(dropdown).toBeInTheDocument()

    // The ObserverOptions component should receive the correct props
    // We can't easily test the props directly, but we can verify the component renders
    // which means it received valid props without type errors

    cleanup()
  })

  it('should handle single observed user scenario', () => {
    const {getByTestId, cleanup} = setup({
      observedUsersList: [{id: '1', name: 'Single Student'}],
      currentUser: {
        id: '123',
        display_name: 'Observer User',
        avatar_image_url: 'observer.jpg',
      },
    })

    // For single user, ObserverOptions renders a label instead of dropdown
    expect(getByTestId('observed-student-label')).toBeInTheDocument()

    cleanup()
  })

  it('should maintain proper layout structure', () => {
    const {container, cleanup} = setup({
      observedUsersList: [
        {id: '1', name: 'Student 1'},
        {id: '2', name: 'Student 2'},
      ],
      currentUser: {
        id: '123',
        display_name: 'Observer User',
        avatar_image_url: 'observer.jpg',
      },
    })

    // Check that the layout uses Flex container
    const flexContainer = container.querySelector('[class*="view"]')
    expect(flexContainer).toBeInTheDocument()

    cleanup()
  })

  it('should render without crashing when context provides minimal data', () => {
    const {getByTestId, cleanup} = setup({
      observedUsersList: [],
      currentUser: null,
      canAddObservee: false,
      currentUserRoles: [],
    })

    expect(getByTestId('dashboard-heading')).toBeInTheDocument()

    cleanup()
  })

  it('should handle empty avatar URLs gracefully', () => {
    const {getByTestId, cleanup} = setup({
      observedUsersList: [{id: '1', name: 'Student Without Avatar'}],
      currentUser: {
        id: '123',
        display_name: 'Observer User',
        avatar_image_url: '',
      },
    })

    // Single user scenario renders label
    expect(getByTestId('observed-student-label')).toBeInTheDocument()

    cleanup()
  })
})
