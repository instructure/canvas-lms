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
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import PeopleWidget from '../PeopleWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'

jest.mock('@canvas/message-students-modal/react', () => {
  return function MockMessageStudents({onRequestClose, title, recipients, contextCode}: any) {
    return (
      <div data-testid="message-students-modal">
        <h2>{title}</h2>
        <div data-testid="modal-context-code">{contextCode}</div>
        <div data-testid="modal-recipients">
          {recipients.map((r: any) => r.displayName).join(', ')}
        </div>
        <button onClick={onRequestClose} data-testid="close-modal">
          Close
        </button>
      </div>
    )
  }
})

const server = setupServer(
  // Mock useSharedCourses query
  graphql.query('GetUserCoursesWithGradesConnection', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [],
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
  // Mock useCourseInstructors query
  graphql.query('GetCourseInstructorsPaginated', () => {
    return HttpResponse.json({
      data: {
        courseInstructorsConnection: {
          nodes: [
            {
              user: {
                _id: '123',
                name: 'John Doe',
                sortableName: 'Doe, John',
                shortName: 'John',
                avatarUrl: 'https://example.com/avatar.jpg',
                email: 'john@example.com',
              },
              course: {
                _id: '789',
                name: 'Computer Science 101',
                courseCode: 'CS101',
              },
              type: 'TeacherEnrollment',
              role: {
                _id: '1',
                name: 'TeacherEnrollment',
              },
              enrollmentState: 'active',
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
    })
  }),
)

const mockWidget: Widget = {
  id: 'test-people-widget',
  type: 'people',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Test People Widget',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}

describe('PeopleWidget', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.ENV = {
      current_user_id: '123',
      GRAPHQL_URL: '/api/graphql',
      CSRF_TOKEN: 'mock-csrf-token',
    } as any
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('renders widget title', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Test People Widget')).toBeInTheDocument()
  })

  it('handles external loading state', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps({isLoading: true})} />)
    expect(screen.getByText('Loading people data...')).toBeInTheDocument()
  })

  it('handles external error state', () => {
    const onRetry = jest.fn()
    renderWithQueryClient(
      <PeopleWidget {...buildDefaultProps({error: 'Failed to load', onRetry})} />,
    )

    expect(screen.getByText('Failed to load')).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Retry'})).toBeInTheDocument()
  })

  it('renders internal loading state when no external props provided', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Loading people data...')).toBeInTheDocument()
  })

  it('has correct data-testid', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByTestId('widget-test-people-widget')).toBeInTheDocument()
  })

  describe('Message Students Modal Integration', () => {
    it('opens message modal when message button is clicked', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('John Doe')

      const messageButton = screen.getByRole('button', {name: /send a message to john doe/i})
      await user.click(messageButton)

      expect(screen.getByTestId('message-students-modal')).toBeInTheDocument()
      expect(screen.getByText('Send Message to John Doe')).toBeInTheDocument()
      expect(screen.getByTestId('modal-context-code')).toHaveTextContent('course_789')
      expect(screen.getByTestId('modal-recipients')).toHaveTextContent('John Doe')
    })

    it('closes message modal when close button is clicked', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('John Doe')
      const messageButton = screen.getByRole('button', {name: /send a message to john doe/i})
      await user.click(messageButton)

      expect(screen.getByTestId('message-students-modal')).toBeInTheDocument()

      const closeButton = screen.getByTestId('close-modal')
      await user.click(closeButton)

      expect(screen.queryByTestId('message-students-modal')).not.toBeInTheDocument()
    })

    it('passes correct recipient data to modal', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('John Doe')

      const messageButton = screen.getByRole('button', {name: /send a message to john doe/i})
      await user.click(messageButton)

      expect(screen.getByTestId('modal-context-code')).toHaveTextContent('course_789')
      expect(screen.getByTestId('modal-recipients')).toHaveTextContent('John Doe')
      expect(screen.getByText('Send Message to John Doe')).toBeInTheDocument()
    })

    it('does not render modal when closed', () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
      expect(screen.queryByTestId('message-students-modal')).not.toBeInTheDocument()
    })
  })
})
