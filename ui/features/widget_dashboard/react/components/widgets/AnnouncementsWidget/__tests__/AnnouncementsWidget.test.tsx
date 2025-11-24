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
import {render, screen, waitFor, fireEvent} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import AnnouncementsWidget from '../AnnouncementsWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {
  WidgetDashboardProvider,
  type SharedCourseData,
} from '../../../../hooks/useWidgetDashboardContext'
import {clearWidgetDashboardCache, defaultGraphQLHandlers} from '../../../../__tests__/testHelpers'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const mockWidget: Widget = {
  id: 'test-announcements-widget',
  type: 'announcements',
  position: {col: 1, row: 1, relative: 1},
  title: 'Announcements',
}

const mockSharedCourseData: SharedCourseData[] = [
  {
    courseId: '1',
    courseCode: 'CS 101',
    courseName: 'Test Course 1',
    currentGrade: 95,
    gradingScheme: [
      ['A', 0.94],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.84],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.74],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.64],
      ['D-', 0.61],
      ['F', 0],
    ] as Array<[string, number]>,
    lastUpdated: '2025-01-01T00:00:00Z',
  },
  {
    courseId: '2',
    courseCode: 'ENG 201',
    courseName: 'Test Course 2',
    currentGrade: 88,
    gradingScheme: 'percentage',
    lastUpdated: '2025-01-02T00:00:00Z',
  },
]

// Mock responses for different read states
const mockAllAnnouncementsResponse = {
  data: {
    legacyNode: {
      _id: '123',
      discussionParticipantsConnection: {
        nodes: [
          {
            id: 'participant1',
            read: true,
            discussionTopic: {
              _id: '1',
              title: 'Test Announcement 1',
              message: '<p>This is a test announcement message</p>',
              createdAt: '2025-01-15T10:00:00Z',
              contextName: 'Test Course 1',
              contextId: '1',
              isAnnouncement: true,
              author: {
                _id: 'user1',
                name: 'Test Teacher 1',
                avatarUrl: 'https://example.com/avatar1.jpg',
              },
            },
          },
          {
            id: 'participant2',
            read: false,
            discussionTopic: {
              _id: '2',
              title: 'Test Announcement 2',
              message: '<p>Another test announcement</p>',
              createdAt: '2025-01-14T15:30:00Z',
              contextName: 'Test Course 2',
              contextId: '2',
              isAnnouncement: true,
              author: {
                _id: 'user2',
                name: 'Test Teacher 2',
                avatarUrl: 'https://example.com/avatar2.jpg',
              },
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          totalCount: null,
        },
      },
    },
  },
}

const mockUnreadAnnouncementsResponse = {
  data: {
    legacyNode: {
      _id: '123',
      discussionParticipantsConnection: {
        nodes: [
          {
            id: 'participant2',
            read: false,
            discussionTopic: {
              _id: '2',
              title: 'Test Announcement 2',
              message: '<p>Another test announcement</p>',
              createdAt: '2025-01-14T15:30:00Z',
              contextName: 'Test Course 2',
              contextId: '2',
              isAnnouncement: true,
              author: {
                _id: 'user2',
                name: 'Test Teacher 2',
                avatarUrl: 'https://example.com/avatar2.jpg',
              },
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          totalCount: null,
        },
      },
    },
  },
}

const emptyAnnouncementsResponse = {
  data: {
    legacyNode: {
      _id: '123',
      discussionParticipantsConnection: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          totalCount: null,
        },
      },
    },
  },
}

const mockReadAnnouncementsResponse = {
  data: {
    legacyNode: {
      _id: '123',
      discussionParticipantsConnection: {
        nodes: [
          {
            id: 'participant1',
            read: true,
            discussionTopic: {
              _id: '1',
              title: 'Test Announcement 1',
              message: '<p>This is a test announcement message</p>',
              createdAt: '2025-01-15T10:00:00Z',
              contextName: 'Test Course 1',
              contextId: '1',
              isAnnouncement: true,
              author: {
                _id: 'user1',
                name: 'Test Teacher 1',
                avatarUrl: 'https://example.com/avatar1.jpg',
              },
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          totalCount: null,
        },
      },
    },
  },
}

// Helper function to get the appropriate mock response based on read state
const getMockResponseForReadState = (readState?: string) => {
  switch (readState) {
    case 'read':
      return mockReadAnnouncementsResponse
    case 'unread':
      return mockUnreadAnnouncementsResponse
    case 'empty':
      return emptyAnnouncementsResponse
    case 'all':
    default:
      return mockAllAnnouncementsResponse
  }
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const setup = (
  props: BaseWidgetProps = buildDefaultProps(),
  envOverrides = {},
  sharedCourseData: SharedCourseData[] = mockSharedCourseData,
) => {
  // Set up Canvas ENV with current_user_id
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
    ...envOverrides,
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = render(<AnnouncementsWidget {...props} />, {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardProvider sharedCourseData={sharedCourseData}>
          <WidgetDashboardEditProvider>
            <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
          </WidgetDashboardEditProvider>
        </WidgetDashboardProvider>
      </QueryClientProvider>
    ),
  })

  return {
    ...result,
    queryClient,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

// Mock course grades data for course code enrichment
const mockCourseGradesResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: [
          {
            course: {
              _id: '1',
              name: 'Test Course 1',
              courseCode: 'MATH 101',
            },
            grades: {
              currentScore: 85,
              currentGrade: 'B',
              finalScore: null,
              finalGrade: null,
              overrideScore: null,
              overrideGrade: null,
            },
          },
          {
            course: {
              _id: '2',
              name: 'Test Course 2',
              courseCode: 'ENG 201',
            },
            grades: {
              currentScore: 92,
              currentGrade: 'A-',
              finalScore: null,
              finalGrade: null,
              overrideScore: null,
              overrideGrade: null,
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          totalCount: null,
        },
      },
    },
  },
}

const server = setupServer(...defaultGraphQLHandlers)

const waitForLoadingToComplete = async () => {
  await waitFor(() => {
    expect(screen.queryByText('Loading announcements...')).not.toBeInTheDocument()
  })
}

describe('AnnouncementsWidget', () => {
  beforeAll(() =>
    server.listen({
      onUnhandledRequest: 'bypass',
    }),
  )
  beforeEach(() => {
    clearWidgetDashboardCache()
  })
  afterEach(() => {
    server.resetHandlers()
  })
  afterAll(() => server.close())

  it('renders loading state initially', () => {
    // Set up a delayed response to ensure we see the loading state
    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(getMockResponseForReadState(variables.readState)))
          }, 100)
        })
      }),
    )

    const {cleanup} = setup()
    expect(screen.getByText('Loading announcements...')).toBeInTheDocument()
    cleanup()
  })

  it('renders announcements list after loading', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        return HttpResponse.json(getMockResponseForReadState(variables.readState))
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    await waitFor(() => {
      // With default "unread" filter, only Test Announcement 2 should show (read: false = unread)
      expect(screen.queryByText('Test Announcement 1')).not.toBeInTheDocument() // This is read
      expect(screen.getByText('Test Announcement 2')).toBeInTheDocument() // This is unread
    })

    cleanup()
  })

  it('renders empty state when no announcements', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              discussionParticipantsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor: null,
                  totalCount: null,
                },
              },
            },
          },
        })
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    expect(screen.getByText('No unread announcements')).toBeInTheDocument()
    cleanup()
  })

  it('renders error state when API request fails', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json({
          errors: [{message: 'GraphQL error'}],
        })
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    await waitFor(() => {
      expect(
        screen.getByText('Failed to load announcements. Please try again.'),
      ).toBeInTheDocument()
      expect(screen.getByText('Retry')).toBeInTheDocument()
    })

    cleanup()
  })

  it('strips HTML from announcement message preview', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        return HttpResponse.json(getMockResponseForReadState(variables.readState))
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    await waitFor(() => {
      // With default "unread" filter, only Test Announcement 2 content should show
      expect(screen.queryByText('This is a test announcement message')).not.toBeInTheDocument() // Test Announcement 1 is read
      expect(screen.getByText('Another test announcement')).toBeInTheDocument() // Test Announcement 2 is unread
    })

    cleanup()
  })

  it('calls GraphQL with correct variables', async () => {
    let capturedVariables: any = null

    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json(getMockResponseForReadState(variables.readState))
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    expect(capturedVariables).not.toBeNull()
    expect(capturedVariables.first).toBe(3)
    expect(capturedVariables.userId).toBe('123') // From ENV.current_user_id

    cleanup()
  })

  it('retries GraphQL call when retry button is clicked', async () => {
    let callCount = 0

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        callCount++
        if (callCount === 1) {
          return HttpResponse.json({
            errors: [{message: 'GraphQL error'}],
          })
        }
        return HttpResponse.json(getMockResponseForReadState('unread'))
      }),
    )

    const {cleanup} = setup()

    // Wait for error state to appear
    await waitFor(() => {
      expect(
        screen.getByText('Failed to load announcements. Please try again.'),
      ).toBeInTheDocument()
    })

    // Click retry button
    const retryButton = screen.getByText('Retry')
    fireEvent.click(retryButton)

    await waitFor(() => {
      expect(screen.getByText('Test Announcement 2')).toBeInTheDocument()
    })

    expect(callCount).toBe(2)
    cleanup()
  })

  it('truncates very long announcement titles and content', async () => {
    const longContentResponse = {
      data: {
        legacyNode: {
          _id: '123',
          discussionParticipantsConnection: {
            nodes: [
              {
                id: 'participant1',
                read: false, // Make it unread so it shows with default "unread" filter
                discussionTopic: {
                  _id: '1',
                  title:
                    'This is an Extremely Long Announcement Title That Should Be Truncated Because It Is Way Too Long For The Widget',
                  message:
                    '<p>This is an extremely long announcement message that contains lots of details and should be truncated to prevent the widget from overflowing beyond its designated boundaries and breaking the layout</p>',
                  createdAt: '2025-01-15T10:00:00Z',
                  contextName:
                    'This is a Very Long Course Name That Should Be Truncated Because It Exceeds Normal Length',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user1',
                    name: 'Test Teacher',
                    avatarUrl: 'https://example.com/avatar.jpg',
                  },
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              totalCount: null,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(longContentResponse)
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    expect(
      screen.getByText(
        /This is an Extremely Long Announcement Title That Should Be Truncated Becau\.\.\./,
      ),
    ).toBeInTheDocument()

    expect(
      screen.getByText(
        /This is an extremely long announcement message that contains lots of details and should be truncated to prevent the widg\.\.\./,
      ),
    ).toBeInTheDocument()

    cleanup()
  })

  it('filters announcements by read status', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        return HttpResponse.json(getMockResponseForReadState(variables.readState))
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    // Default filter should be "unread" - only Test Announcement 2 should show
    expect(screen.queryByText('Test Announcement 1')).not.toBeInTheDocument()
    expect(screen.getByText('Test Announcement 2')).toBeInTheDocument()

    // Find the filter dropdown and change to "read"
    const filterDropdown = screen.getByTitle('Unread')
    fireEvent.click(filterDropdown)

    // Click on "Read" option
    const readOption = await screen.findByText('Read')
    fireEvent.click(readOption)

    // Now only read announcements should show
    await waitFor(() => {
      expect(screen.getByText('Test Announcement 1')).toBeInTheDocument()
      expect(screen.queryByText('Test Announcement 2')).not.toBeInTheDocument()
    })

    // Change to "All" filter
    const updatedDropdown = screen.getByTitle('Read')
    fireEvent.click(updatedDropdown)

    const allOption = await screen.findByText('All')
    fireEvent.click(allOption)

    // Now both announcements should show
    await waitFor(() => {
      expect(screen.getByText('Test Announcement 1')).toBeInTheDocument()
      expect(screen.getByText('Test Announcement 2')).toBeInTheDocument()
    })

    cleanup()
  })

  it('toggles read/unread status when buttons are clicked', async () => {
    // Mock the mutation response
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(getMockResponseForReadState('unread'))
      }),
      graphql.mutation('UpdateDiscussionReadState', ({variables}) => {
        return HttpResponse.json({
          data: {
            updateDiscussionReadState: {
              discussionTopic: {
                _id: '2',
              },
            },
          },
        })
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    // Default filter is "unread" - should show Test Announcement 2 (unread)
    await waitFor(() => {
      expect(screen.getByText('Test Announcement 2')).toBeInTheDocument()
    })

    const announctmentItemContainer = screen.getByTestId('announcement-item-2')
    expect(announctmentItemContainer).toBeInTheDocument()

    // Find and click the mark as read button for Test Announcement 2
    const markReadButton = screen.getByTestId('mark-read-2')
    expect(markReadButton).toBeInTheDocument()

    fireEvent.click(markReadButton)

    await waitFor(() => {
      expect(markReadButton).toBeDisabled()
    })

    cleanup()
  })

  it('shows pagination controls when there are multiple pages', async () => {
    // Mock response with hasNextPage: true to show pagination
    const paginatedResponse = {
      data: {
        legacyNode: {
          _id: '123',
          discussionParticipantsConnection: {
            nodes: [
              {
                id: 'participant1',
                read: true,
                discussionTopic: {
                  _id: '1',
                  title: 'Test Announcement 1',
                  message: '<p>This is a test announcement message</p>',
                  createdAt: '2025-01-15T10:00:00Z',
                  contextName: 'Test Course 1',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user1',
                    name: 'Test Teacher 1',
                    avatarUrl: 'https://example.com/avatar1.jpg',
                  },
                },
              },
            ],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'start-cursor',
              endCursor: 'end-cursor',
              totalCount: 6,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(paginatedResponse)
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    // Change to "all" filter to see the announcement
    const filterSelect = screen.getByDisplayValue('Unread')
    fireEvent.click(filterSelect)
    fireEvent.click(screen.getByText('All'))

    await waitFor(() => {
      expect(screen.getByText('Test Announcement 1')).toBeInTheDocument()
    })

    // Check that pagination controls are visible
    await waitFor(() => {
      // Check for Instructure UI Pagination component
      const paginationNav = screen.getByTestId('pagination-container')
      expect(paginationNav).toBeInTheDocument()

      // Check for page buttons by text content
      expect(screen.getByText('1')).toBeInTheDocument()
      expect(screen.getByText('2')).toBeInTheDocument()
    })

    cleanup()
  })

  it('renders course code pills from shared course data lookup', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        return HttpResponse.json(getMockResponseForReadState(variables.readState))
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    await waitFor(() => {
      expect(screen.getByText('Test Announcement 2')).toBeInTheDocument()
    })

    expect(screen.getByText('ENG 201')).toBeInTheDocument()

    cleanup()
  })

  it('decodes HTML entities in announcement messages', async () => {
    const htmlEntitiesResponse = {
      data: {
        legacyNode: {
          _id: '123',
          discussionParticipantsConnection: {
            nodes: [
              {
                id: 'participant1',
                read: false,
                discussionTopic: {
                  _id: '1',
                  title: 'Test Announcement with Entities',
                  message:
                    '<p>Test&nbsp;with&nbsp;non-breaking&nbsp;spaces&amp;ampersands&lt;brackets&gt;</p>',
                  createdAt: '2025-01-15T10:00:00Z',
                  contextName: 'Test Course',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user1',
                    name: 'Test Teacher',
                    avatarUrl: 'https://example.com/avatar.jpg',
                  },
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              totalCount: null,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(htmlEntitiesResponse)
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    await waitFor(() => {
      // Should show decoded entities: non-breaking spaces, ampersands, and brackets
      expect(
        screen.getByText(/Test with non-breaking spaces&ampersands<brackets>/),
      ).toBeInTheDocument()
    })

    cleanup()
  })

  it('maintains pagination visibility when switching filters', async () => {
    // Mock paginated responses for different filters
    const paginatedUnreadResponse = {
      data: {
        legacyNode: {
          _id: '123',
          discussionParticipantsConnection: {
            nodes: [
              {
                id: 'participant1',
                read: false,
                discussionTopic: {
                  _id: '1',
                  title: 'Unread Announcement 1',
                  message: '<p>Unread message</p>',
                  createdAt: '2025-01-15T10:00:00Z',
                  contextName: 'Test Course 1',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user1',
                    name: 'Test Teacher 1',
                    avatarUrl: 'https://example.com/avatar1.jpg',
                  },
                },
              },
            ],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'start-cursor',
              endCursor: 'end-cursor',
              totalCount: 6,
            },
          },
        },
      },
    }

    const paginatedAllResponse = {
      data: {
        legacyNode: {
          _id: '123',
          discussionParticipantsConnection: {
            nodes: [
              {
                id: 'participant1',
                read: true,
                discussionTopic: {
                  _id: '2',
                  title: 'All Announcement 1',
                  message: '<p>All message</p>',
                  createdAt: '2025-01-15T10:00:00Z',
                  contextName: 'Test Course 1',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user1',
                    name: 'Test Teacher 1',
                    avatarUrl: 'https://example.com/avatar1.jpg',
                  },
                },
              },
            ],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'start-cursor-all',
              endCursor: 'end-cursor-all',
              totalCount: 9,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        if (variables.readState === 'unread') {
          return HttpResponse.json(paginatedUnreadResponse)
        }
        return HttpResponse.json(paginatedAllResponse)
      }),
    )

    const {cleanup} = setup()

    await waitForLoadingToComplete()

    // Wait for initial pagination to appear with "unread" filter
    await waitFor(() => {
      const paginationContainer = screen.getByTestId('pagination-container')
      expect(paginationContainer).toBeInTheDocument()
      expect(screen.getByText('1')).toBeInTheDocument()
      expect(screen.getByText('2')).toBeInTheDocument()
    })

    // Change filter to "all"
    const filterDropdown = screen.getByTitle('Unread')
    fireEvent.click(filterDropdown)

    const allOption = await screen.findByText('All')
    fireEvent.click(allOption)

    // Pagination should remain visible during and after filter change
    await waitFor(() => {
      const paginationContainer = screen.getByTestId('pagination-container')
      expect(paginationContainer).toBeInTheDocument()
    })

    // Verify new pagination reflects the "all" filter's total count
    await waitFor(() => {
      expect(screen.getByText('1')).toBeInTheDocument()
      expect(screen.getByText('2')).toBeInTheDocument()
      expect(screen.getByText('3')).toBeInTheDocument() // 9 items / 3 per page = 3 pages
    })

    cleanup()
  })
})
