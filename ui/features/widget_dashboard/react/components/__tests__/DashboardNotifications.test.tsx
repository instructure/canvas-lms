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
import {MockedProvider} from '@apollo/client/testing'
import '@testing-library/jest-dom'
import {DashboardNotifications} from '../DashboardNotifications'
import {gql} from '@apollo/client'

const ACCOUNT_NOTIFICATIONS_QUERY = gql`
  query GetAccountNotifications {
    accountNotifications {
      id
      _id
      subject
      message
      startAt
      endAt
      accountName
      siteAdmin
      notificationType
    }
  }
`

const DISMISS_NOTIFICATION_MUTATION = gql`
  mutation DismissAccountNotification($notificationId: ID!) {
    dismissAccountNotification(input: {notificationId: $notificationId}) {
      errors { message }
    }
  }
`

describe('DashboardNotifications', () => {
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

  const mocks = [
    {
      request: {
        query: ACCOUNT_NOTIFICATIONS_QUERY,
      },
      result: {
        data: {
          accountNotifications: mockNotifications,
        },
      },
    },
  ]

  it('renders loading state initially', () => {
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    expect(screen.getByText('Loading notifications')).toBeInTheDocument()
  })

  it('renders notifications after loading', async () => {
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('First Notification')).toBeInTheDocument()
      expect(screen.getByText('Second Notification')).toBeInTheDocument()
    })
  })

  it('hides notification when dismissed', async () => {
    const dismissMock = {
      request: {
        query: DISMISS_NOTIFICATION_MUTATION,
        variables: {
          notificationId: '1',
        },
      },
      result: {
        data: {
          dismissAccountNotification: {
            success: true,
          },
        },
      },
    }

    const mocksWithDismiss = [...mocks, dismissMock]

    render(
      <MockedProvider mocks={mocksWithDismiss} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('First Notification')).toBeInTheDocument()
    })

    const closeButtons = screen.getAllByText('Close')
    fireEvent.click(closeButtons[0])

    await waitFor(() => {
      expect(screen.queryByText('First Notification')).not.toBeInTheDocument()
      expect(screen.getByText('Second Notification')).toBeInTheDocument()
    })
  })

  it('renders nothing when there are no notifications', async () => {
    const emptyMocks = [
      {
        request: {
          query: ACCOUNT_NOTIFICATIONS_QUERY,
        },
        result: {
          data: {
            accountNotifications: [],
          },
        },
      },
    ]

    const {container} = render(
      <MockedProvider mocks={emptyMocks} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(container.firstChild).toBeNull()
    })
  })

  it('handles error gracefully', async () => {
    const errorMocks = [
      {
        request: {
          query: ACCOUNT_NOTIFICATIONS_QUERY,
        },
        error: new Error('Failed to fetch'),
      },
    ]

    const {container} = render(
      <MockedProvider mocks={errorMocks} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(container.firstChild).toBeNull()
    })
  })

  it('handles dismiss mutation error gracefully', async () => {
    const dismissErrorMock = {
      request: {
        query: DISMISS_NOTIFICATION_MUTATION,
        variables: {
          notificationId: '1',
        },
      },
      error: new Error('Failed to dismiss'),
    }

    const mocksWithError = [...mocks, dismissErrorMock]
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

    render(
      <MockedProvider mocks={mocksWithError} addTypename={false}>
        <DashboardNotifications />
      </MockedProvider>,
    )

    await waitFor(() => {
      const hasFirstNotification = screen.queryByText('First Notification')
      const hasSecondNotification = screen.queryByText('Second Notification')
      expect(hasFirstNotification || hasSecondNotification).toBeTruthy()
    })

    const closeButtons = screen.getAllByText('Close')
    fireEvent.click(closeButtons[0])

    await waitFor(() => {
      expect(consoleSpy).toHaveBeenCalledWith('Failed to dismiss notification:', expect.any(Error))
    })

    await waitFor(() => {
      const closeButtonsAfter = screen.getAllByText('Close')
      expect(closeButtonsAfter).toHaveLength(1)
    })

    consoleSpy.mockRestore()
  })
})
