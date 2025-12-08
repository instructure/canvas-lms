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
import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import InboxWidget from '../InboxWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {
  WidgetDashboardProvider,
  type SharedCourseData,
} from '../../../../hooks/useWidgetDashboardContext'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const mockWidget: Widget = {
  id: 'test-inbox-widget',
  type: 'inbox',
  position: {col: 1, row: 1, relative: 1},
  title: 'Inbox',
}

const mockSharedCourseData: SharedCourseData[] = []

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const renderWithProviders = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider sharedCourseData={mockSharedCourseData}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>{component}</WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )
}

describe('InboxWidget', () => {
  it('renders widget with title', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Inbox')).toBeInTheDocument()
  })

  it('renders filter dropdown with default value', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)
    const filterSelect = screen.getByTestId('inbox-filter-select')
    expect(filterSelect).toBeInTheDocument()
  })

  it('renders mock message items', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByTestId('message-item-1')).toBeInTheDocument()
    expect(screen.getByTestId('message-item-2')).toBeInTheDocument()
    expect(screen.getByTestId('message-item-3')).toBeInTheDocument()
  })

  it('displays message sender names', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText('John Smith')).toBeInTheDocument()
    expect(screen.getByText('Sarah Johnson')).toBeInTheDocument()
    expect(screen.getByText('Mike Davis')).toBeInTheDocument()
  })

  it('displays message subjects', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Assignment feedback available')).toBeInTheDocument()
    expect(screen.getByText('Course announcement: Quiz next week')).toBeInTheDocument()
    expect(screen.getByText('Group project update')).toBeInTheDocument()
  })

  it('displays message previews', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Hey, I left some feedback on your...')).toBeInTheDocument()
    expect(screen.getByText('Just a reminder that we have a quiz...')).toBeInTheDocument()
    expect(screen.getByText('The group project deadline has been...')).toBeInTheDocument()
  })

  it('renders "Open in Inbox" links for each message', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const openLinks = screen.getAllByText('Open in Inbox')
    expect(openLinks).toHaveLength(3)
  })

  it('renders "Show all messages in inbox" action link', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const showAllLink = screen.getByTestId('show-all-messages-link')
    expect(showAllLink).toBeInTheDocument()
    expect(showAllLink).toHaveAttribute('href', '/conversations')
  })

  it('renders avatars for message senders', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const messageItems = screen.getAllByTestId(/^message-item-/)
    expect(messageItems).toHaveLength(3)
  })

  it('handles loading state', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps({isLoading: true})} />)

    expect(screen.getByText(/loading/i)).toBeInTheDocument()
    expect(screen.queryByText('John Smith')).not.toBeInTheDocument()
  })

  it('handles error state with retry button', () => {
    const onRetry = jest.fn()
    renderWithProviders(
      <InboxWidget
        {...buildDefaultProps({
          error: 'Failed to load messages',
          onRetry,
        })}
      />,
    )

    expect(screen.getByText('Failed to load messages')).toBeInTheDocument()
    const retryButton = screen.getByTestId('test-inbox-widget-retry-button')
    expect(retryButton).toBeInTheDocument()
    expect(screen.queryByText('John Smith')).not.toBeInTheDocument()
  })

  it('truncates long subject lines', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const subjects = screen.getAllByText((content, element) => {
      return element?.tagName.toLowerCase() === 'span' && content.length > 0
    })

    subjects.forEach(subject => {
      expect(subject.textContent?.length || 0).toBeLessThanOrEqual(63)
    })
  })
})
