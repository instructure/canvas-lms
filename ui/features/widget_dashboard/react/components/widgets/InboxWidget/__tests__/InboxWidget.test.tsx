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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {type MockedFunction} from 'vitest'
import InboxWidget from '../InboxWidget'
import type {BaseWidgetProps, Widget, InboxMessage} from '../../../../types'
import {
  WidgetDashboardProvider,
  type SharedCourseData,
} from '../../../../hooks/useWidgetDashboardContext'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'
import * as useInboxMessagesModule from '../../../../hooks/useInboxMessages'
import * as useWidgetConfigModule from '../../../../hooks/useWidgetConfig'

vi.mock('../../../../hooks/useInboxMessages')
vi.mock('../../../../hooks/useWidgetConfig')

const mockUseInboxMessages = useInboxMessagesModule.useInboxMessages as MockedFunction<
  typeof useInboxMessagesModule.useInboxMessages
>

const mockUseWidgetConfig = useWidgetConfigModule.useWidgetConfig as MockedFunction<
  typeof useWidgetConfigModule.useWidgetConfig
>

const mockMessages: InboxMessage[] = [
  {
    id: '1',
    subject: 'Assignment feedback available',
    lastMessageAt: '2025-12-08T10:00:00Z',
    messagePreview: 'Hey, I left some feedback on your...',
    workflowState: 'unread',
    conversationUrl: '/conversations/1',
    participants: [
      {
        id: 'user1',
        name: 'John Smith',
        avatarUrl: undefined,
      },
    ],
  },
  {
    id: '2',
    subject: 'Course announcement: Quiz next week',
    lastMessageAt: '2025-12-07T14:30:00Z',
    messagePreview: 'Just a reminder that we have a quiz...',
    workflowState: 'unread',
    conversationUrl: '/conversations/2',
    participants: [
      {
        id: 'user2',
        name: 'Sarah Johnson',
        avatarUrl: undefined,
      },
    ],
  },
  {
    id: '3',
    subject: 'Group project update',
    lastMessageAt: '2025-12-05T09:15:00Z',
    messagePreview: 'The group project deadline has been...',
    workflowState: 'unread',
    conversationUrl: '/conversations/3',
    participants: [
      {
        id: 'user3',
        name: 'Mike Davis',
        avatarUrl: undefined,
      },
    ],
  },
]

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
  let mockSetFilter: ReturnType<typeof vi.fn>

  beforeEach(() => {
    mockSetFilter = vi.fn()
    mockUseWidgetConfig.mockReturnValue(['unread', mockSetFilter])
    mockUseInboxMessages.mockReturnValue({
      data: mockMessages,
      isLoading: false,
      error: null,
      refetch: vi.fn(),
    } as any)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders widget with title', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Inbox')).toBeInTheDocument()
  })

  it('renders filter dropdown with default value', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)
    const filterSelect = screen.getByTestId('inbox-filter-select')
    expect(filterSelect).toBeInTheDocument()
  })

  it('renders message items', () => {
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
    mockUseInboxMessages.mockReturnValue({
      data: [],
      isLoading: true,
      error: null,
      refetch: vi.fn(),
    } as any)

    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText(/loading/i)).toBeInTheDocument()
    expect(screen.queryByText('John Smith')).not.toBeInTheDocument()
  })

  it('handles error state with retry button', async () => {
    const mockRefetch = vi.fn()
    mockUseInboxMessages.mockReturnValue({
      data: [],
      isLoading: false,
      error: new Error('Failed to load messages'),
      refetch: mockRefetch,
    } as any)

    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Error: Failed to load messages')).toBeInTheDocument()
    const retryButton = screen.getByTestId('test-inbox-widget-retry-button')
    expect(retryButton).toBeInTheDocument()

    await userEvent.click(retryButton)
    expect(mockRefetch).toHaveBeenCalled()
  })

  it('handles empty state when no messages', () => {
    mockUseInboxMessages.mockReturnValue({
      data: [],
      isLoading: false,
      error: null,
      refetch: vi.fn(),
    } as any)

    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(screen.getByText('No messages')).toBeInTheDocument()
  })

  it('changes filter when dropdown selection changes', async () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const filterSelect = screen.getByTestId('inbox-filter-select')
    expect(filterSelect).toBeInTheDocument()

    expect(mockUseInboxMessages).toHaveBeenCalledWith(expect.objectContaining({filter: 'unread'}))
  })

  it('loads persisted filter preference on mount', () => {
    mockUseWidgetConfig.mockReturnValue(['all', mockSetFilter])

    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(mockUseWidgetConfig).toHaveBeenCalledWith('test-inbox-widget', 'filter', 'unread')
    expect(mockUseInboxMessages).toHaveBeenCalledWith(expect.objectContaining({filter: 'all'}))
  })

  it('saves filter preference when changed', async () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    const filterSelect = screen.getByTestId('inbox-filter-select')
    await userEvent.click(filterSelect)

    const allOption = screen.getByText('All')
    await userEvent.click(allOption)

    expect(mockSetFilter).toHaveBeenCalledWith('all')
  })

  it('defaults to unread filter when no preference saved', () => {
    renderWithProviders(<InboxWidget {...buildDefaultProps()} />)

    expect(mockUseWidgetConfig).toHaveBeenCalledWith('test-inbox-widget', 'filter', 'unread')
    expect(mockUseInboxMessages).toHaveBeenCalledWith(expect.objectContaining({filter: 'unread'}))
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
