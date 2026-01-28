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
import WidgetDashboardContainer from '../WidgetDashboardContainer'
import {WidgetDashboardProvider} from '../hooks/useWidgetDashboardContext'
import {WidgetDashboardEditProvider} from '../hooks/useWidgetDashboardEdit'
import {WidgetLayoutProvider} from '../hooks/useWidgetLayout'
import {ResponsiveProvider} from '../hooks/useResponsiveContext'
import {defaultGraphQLHandlers, clearWidgetDashboardCache} from './testHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

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
      queryClient.clear()
    },
  }
}

describe('WidgetDashboardContainer - Customization', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    fakeENV.setup({
      current_user_id: '123',
    })
    clearWidgetDashboardCache()
  })

  afterEach(() => {
    server.resetHandlers()
    if (queryClient) {
      queryClient.clear()
    }
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  it('should not show customize button when feature flag is disabled', () => {
    const {queryByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: false,
      },
    })

    expect(queryByTestId('customize-dashboard-button')).not.toBeInTheDocument()

    cleanup()
  })

  it('should show customize button when feature flag is enabled', () => {
    const {getByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()

    cleanup()
  })

  it('should enter edit mode when customize button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    const customizeButton = getByTestId('customize-dashboard-button')
    await user.click(customizeButton)

    await waitFor(() => {
      expect(queryByTestId('customize-dashboard-button')).not.toBeInTheDocument()
      expect(getByTestId('save-customize-button')).toBeInTheDocument()
      expect(getByTestId('cancel-customize-button')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should exit edit mode when cancel button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    const customizeButton = getByTestId('customize-dashboard-button')
    await user.click(customizeButton)

    expect(getByTestId('cancel-customize-button')).toBeInTheDocument()

    const cancelButton = getByTestId('cancel-customize-button')
    await user.click(cancelButton)

    await waitFor(() => {
      expect(queryByTestId('cancel-customize-button')).not.toBeInTheDocument()
      expect(queryByTestId('save-customize-button')).not.toBeInTheDocument()
      expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should call GraphQL mutation with correct payload when save button is clicked', async () => {
    const user = userEvent.setup()
    let capturedVariables: any = null

    server.use(
      graphql.mutation('UpdateWidgetDashboardLayout', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json({
          data: {
            updateWidgetDashboardLayout: {
              layout: variables.layout,
              errors: null,
            },
          },
        })
      }),
    )

    const {getByTestId, queryByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    const customizeButton = getByTestId('customize-dashboard-button')
    await user.click(customizeButton)

    const saveButton = getByTestId('save-customize-button')
    await user.click(saveButton)

    await waitFor(() => {
      expect(capturedVariables).not.toBeNull()
      expect(capturedVariables.layout).toBeDefined()
      const parsedLayout = JSON.parse(capturedVariables.layout)
      expect(parsedLayout).toHaveProperty('columns')
      expect(parsedLayout).toHaveProperty('widgets')
    })

    await waitFor(() => {
      expect(queryByTestId('save-customize-button')).not.toBeInTheDocument()
      expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
    })

    cleanup()
  })

  it('should display error alert when save mutation fails', async () => {
    const user = userEvent.setup()
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.mutation('UpdateWidgetDashboardLayout', () => {
        return HttpResponse.json({
          data: {
            updateWidgetDashboardLayout: {
              layout: null,
              errors: [{message: 'Invalid widget configuration'}],
            },
          },
        })
      }),
    )

    const {getByTestId, findByText, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    const customizeButton = getByTestId('customize-dashboard-button')
    await user.click(customizeButton)

    const saveButton = getByTestId('save-customize-button')
    await user.click(saveButton)

    const errorAlert = await findByText(/Invalid widget configuration/i)
    expect(errorAlert).toBeInTheDocument()

    consoleErrorSpy.mockRestore()
    cleanup()
  })

  it('should display error alert when network error occurs', async () => {
    const user = userEvent.setup()
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.mutation('UpdateWidgetDashboardLayout', () => {
        return HttpResponse.json({errors: [{message: 'Network error'}]}, {status: 500})
      }),
    )

    const {getByTestId, findByText, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    const customizeButton = getByTestId('customize-dashboard-button')
    await user.click(customizeButton)

    const saveButton = getByTestId('save-customize-button')
    await user.click(saveButton)

    const errorText = await findByText(/Failed to save widget layout/i)
    expect(errorText).toBeInTheDocument()

    consoleErrorSpy.mockRestore()
    cleanup()
  })

  it('should complete full save flow and exit edit mode on success', async () => {
    const user = userEvent.setup()
    server.use(
      graphql.mutation('UpdateWidgetDashboardLayout', ({variables}) => {
        return HttpResponse.json({
          data: {
            updateWidgetDashboardLayout: {
              layout: variables.layout,
              errors: null,
            },
          },
        })
      }),
    )

    const {getByTestId, queryByTestId, cleanup} = setup({
      dashboardFeatures: {
        widget_dashboard_customization: true,
      },
    })

    await user.click(getByTestId('customize-dashboard-button'))

    expect(getByTestId('save-customize-button')).toBeInTheDocument()

    await user.click(getByTestId('save-customize-button'))

    await waitFor(() => {
      expect(queryByTestId('save-customize-button')).not.toBeInTheDocument()
      expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
    })

    cleanup()
  })
})
