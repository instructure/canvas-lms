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
import {clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'

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
  position: {col: 1, row: 1, relative: 1},
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

  beforeEach(() => {
    clearWidgetDashboardCache()
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

  describe('Multiple Instructors', () => {
    beforeEach(() => {
      server.use(
        graphql.query('GetCourseInstructorsPaginated', () => {
          return HttpResponse.json({
            data: {
              courseInstructorsConnection: {
                nodes: [
                  {
                    user: {
                      _id: '1',
                      name: 'Alice Teacher',
                      sortableName: 'Teacher, Alice',
                      shortName: 'Alice',
                      avatarUrl: 'https://example.com/alice.jpg',
                      email: 'alice@example.com',
                    },
                    course: {_id: '100', name: 'Math 101', courseCode: 'MATH101'},
                    type: 'TeacherEnrollment',
                    role: {_id: '1', name: 'TeacherEnrollment'},
                    enrollmentState: 'active',
                  },
                  {
                    user: {
                      _id: '2',
                      name: 'Bob TA',
                      sortableName: 'TA, Bob',
                      shortName: 'Bob',
                      avatarUrl: 'https://example.com/bob.jpg',
                      email: 'bob@example.com',
                    },
                    course: {_id: '100', name: 'Math 101', courseCode: 'MATH101'},
                    type: 'TaEnrollment',
                    role: {_id: '2', name: 'TaEnrollment'},
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
    })

    it('renders all instructors in response', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('Alice Teacher')
      expect(screen.getByText('Bob TA')).toBeInTheDocument()
      expect(screen.getAllByRole('button', {name: /send a message to/i})).toHaveLength(2)
    })

    it('displays TA role correctly', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('Bob TA')
      expect(screen.getByText('Teaching Assistant')).toBeInTheDocument()
      expect(screen.getByText('Teacher')).toBeInTheDocument()
    })

    it('displays email for both instructors', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('alice@example.com')
      expect(screen.getByText('bob@example.com')).toBeInTheDocument()
    })
  })

  describe('Empty State', () => {
    beforeEach(() => {
      server.use(
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
    })

    it('displays "No instructors found" when response is empty', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByTestId('no-instructors-message')
      expect(screen.getByText('No instructors found')).toBeInTheDocument()
    })
  })

  describe('GraphQL Errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
      server.use(
        graphql.query('GetCourseInstructorsPaginated', () => {
          return HttpResponse.json({
            errors: [{message: 'Network error'}],
          })
        }),
      )
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    it('displays error message when query fails', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText(/Failed to load instructor data/i)
    })
  })

  describe('Pagination', () => {
    beforeEach(() => {
      server.use(
        graphql.query('GetCourseInstructorsPaginated', () => {
          return HttpResponse.json({
            data: {
              courseInstructorsConnection: {
                nodes: [
                  {
                    user: {
                      _id: '1',
                      name: 'Instructor 1',
                      sortableName: 'Instructor 1',
                      shortName: 'Inst 1',
                      avatarUrl: null,
                      email: 'inst1@example.com',
                    },
                    course: {_id: '100', name: 'Course 1', courseCode: 'C1'},
                    type: 'TeacherEnrollment',
                    role: {_id: '1', name: 'TeacherEnrollment'},
                    enrollmentState: 'active',
                  },
                ],
                pageInfo: {
                  hasNextPage: true,
                  hasPreviousPage: false,
                  startCursor: 'cursor1',
                  endCursor: 'cursor2',
                  totalCount: 10,
                },
              },
            },
          })
        }),
      )
    })

    it('displays pagination controls when totalPages > 1', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('Instructor 1')

      // Pagination should be rendered
      expect(screen.getByLabelText('Instructors pagination')).toBeInTheDocument()
    })

    it('navigates to next page when next button clicked', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('Instructor 1')

      // Look for page 2 button
      const page2Button = screen.getByRole('button', {name: '2'})
      await user.click(page2Button)

      // Should request next page (implementation would need to verify GraphQL call)
    })
  })

  describe('Missing Email', () => {
    beforeEach(() => {
      server.use(
        graphql.query('GetCourseInstructorsPaginated', () => {
          return HttpResponse.json({
            data: {
              courseInstructorsConnection: {
                nodes: [
                  {
                    user: {
                      _id: '1',
                      name: 'No Email Instructor',
                      sortableName: 'Instructor, No Email',
                      shortName: 'No Email',
                      avatarUrl: null,
                      email: null,
                    },
                    course: {_id: '100', name: 'Course 1', courseCode: 'C1'},
                    type: 'TeacherEnrollment',
                    role: {_id: '1', name: 'TeacherEnrollment'},
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
    })

    it('renders instructor without email gracefully', async () => {
      renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)

      await screen.findByText('No Email Instructor')
      expect(screen.getByRole('button', {name: /send a message to/i})).toBeInTheDocument()
    })
  })
})
