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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import DashboardNotifications from '../DashboardNotifications'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockNotifications = [
  {
    id: '1',
    _id: '1',
    subject: 'First Notification',
    message: '<p>First message</p>',
    startAt: '2025-01-01T00:00:00Z',
    endAt: '2025-12-31T23:59:59Z',
    accountName: 'Test Account',
    siteAdmin: false,
    notificationType: 'info',
  },
  {
    id: '2',
    _id: '2',
    subject: 'Second Notification',
    message: '<p>Second message</p>',
    startAt: '2025-01-01T00:00:00Z',
    endAt: '2025-12-31T23:59:59Z',
    accountName: null,
    siteAdmin: true,
    notificationType: 'warning',
  },
]

const mockInvitations = [
  {
    id: 'inv1',
    uuid: 'abc123',
    course: {
      id: '1',
      name: 'Test Course',
    },
    role: {
      name: 'StudentEnrollment',
    },
    roleLabel: 'Student',
  },
]

const server = setupServer()

describe('DashboardNotifications', () => {
  let queryClient: QueryClient

  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'bypass',
    })
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient?.clear()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    clearWidgetDashboardCache()
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          gcTime: 0,
        },
      },
    })

    window.ENV = {
      ...window.ENV,
      current_user_id: '123',
    } as any
  })

  const renderWithQueryClient = (component: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{component}</QueryClientProvider>)
  }

  it('renders loading state initially', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', async () => {
        await new Promise(() => {})
      }),
    )

    renderWithQueryClient(<DashboardNotifications />)

    expect(screen.getByText('Loading notifications')).toBeInTheDocument()
  })

  it('renders notifications after loading', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', () => {
        return HttpResponse.json({
          data: {
            accountNotifications: mockNotifications,
            enrollmentInvitations: [],
          },
        })
      }),
    )

    renderWithQueryClient(<DashboardNotifications />)

    await waitFor(() => {
      expect(screen.getByText('First Notification')).toBeInTheDocument()
      expect(screen.getByText('Second Notification')).toBeInTheDocument()
    })
  })

  it('renders enrollment invitations', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', () => {
        return HttpResponse.json({
          data: {
            accountNotifications: [],
            enrollmentInvitations: mockInvitations,
          },
        })
      }),
    )

    renderWithQueryClient(<DashboardNotifications />)

    await waitFor(() => {
      expect(screen.getByText(/You have been invited to join/)).toBeInTheDocument()
      expect(screen.getByText('Test Course')).toBeInTheDocument()
    })
  })

  it('handles dismiss notification', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', () => {
        return HttpResponse.json({
          data: {
            accountNotifications: mockNotifications,
            enrollmentInvitations: [],
          },
        })
      }),
      graphql.mutation('DismissAccountNotification', () => {
        return HttpResponse.json({
          data: {
            dismissAccountNotification: {
              errors: null,
            },
          },
        })
      }),
    )

    renderWithQueryClient(<DashboardNotifications />)

    await waitFor(() => {
      expect(screen.getByText('First Notification')).toBeInTheDocument()
    })

    const firstNotification = screen
      .getByText('First Notification')
      .closest('[class*="view-alert"]')
    const dismissButton = firstNotification?.querySelector('button')
    fireEvent.click(dismissButton!)

    await waitFor(() => {
      expect(screen.queryByText('First Notification')).not.toBeInTheDocument()
    })
  })

  it('renders nothing when there are no notifications', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', () => {
        return HttpResponse.json({
          data: {
            accountNotifications: [],
            enrollmentInvitations: [],
          },
        })
      }),
    )

    const {container} = renderWithQueryClient(<DashboardNotifications />)

    await waitFor(() => {
      expect(container.firstChild).toBeNull()
    })
  })

  it('handles error gracefully', async () => {
    server.use(
      graphql.query('GetDashboardNotifications', () => {
        return HttpResponse.json(
          {
            errors: [{message: 'GraphQL error'}],
          },
          {status: 500},
        )
      }),
    )

    const {container} = renderWithQueryClient(<DashboardNotifications />)

    await waitFor(() => {
      expect(container.firstChild).toBeNull()
    })
  })
})
