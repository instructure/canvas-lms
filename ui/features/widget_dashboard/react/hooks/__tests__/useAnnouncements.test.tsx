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

import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {usePaginatedAnnouncements} from '../useAnnouncements'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockGqlResponse = {
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
        },
      },
    },
  },
}

const buildDefaultProps = (overrides = {}) => ({
  limit: 10,
  ...overrides,
})

const setup = (props = {}, envOverrides = {}) => {
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

  const hookParams = buildDefaultProps(props)
  const result = renderHook(() => usePaginatedAnnouncements(hookParams), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
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

const server = setupServer()

describe('usePaginatedAnnouncements', () => {
  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'bypass',
    })
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

  it('should fetch announcements successfully', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup()

    expect(result.current.isLoading).toBe(true)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data?.pages).toHaveLength(1)
      expect(result.current.data?.pages[0]?.announcements).toHaveLength(2)
      expect(result.current.error).toBeNull()
    })

    expect(result.current.data?.pages[0]?.announcements[0]).toEqual({
      id: '1',
      title: 'Test Announcement 1',
      message: '<p>This is a test announcement message</p>',
      posted_at: '2025-01-15T10:00:00Z',
      html_url: '/courses/1/discussion_topics/1',
      context_code: 'course_1',
      course: {
        id: '1',
        name: 'Test Course 1',
      },
      author: {
        _id: 'user1',
        name: 'Test Teacher 1',
        avatarUrl: 'https://example.com/avatar1.jpg',
      },
      isRead: true,
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json({
          errors: [{message: 'GraphQL error'}],
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeTruthy()
    })

    cleanup()
  })

  it('should handle empty enrollments', async () => {
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
                },
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data?.pages).toHaveLength(1)
    expect(result.current.data?.pages[0]?.announcements).toEqual([])
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should handle no user data', async () => {
    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json({
          data: {
            legacyNode: null,
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data?.pages).toHaveLength(1)
    expect(result.current.data?.pages[0]?.announcements).toEqual([])
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should respect the limit parameter', async () => {
    let capturedVariables: any

    server.use(
      graphql.query('GetUserAnnouncements', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup({limit: 5})

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(capturedVariables.first).toBe(5)

    cleanup()
  })

  it('should sort announcements by creation date descending', async () => {
    const sortedResponse = {
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
                  title: 'Newer Announcement',
                  message: 'Newer',
                  createdAt: '2025-01-20T10:00:00Z',
                  contextName: 'Test Course',
                  contextId: '1',
                  isAnnouncement: true,
                  author: {
                    _id: 'user2',
                    name: 'Test Teacher 2',
                    avatarUrl: 'https://example.com/avatar2.jpg',
                  },
                },
              },
              {
                id: 'participant1',
                read: false,
                discussionTopic: {
                  _id: '1',
                  title: 'Older Announcement',
                  message: 'Older',
                  createdAt: '2025-01-10T10:00:00Z',
                  contextName: 'Test Course',
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
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(sortedResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data?.pages).toHaveLength(1)
    expect(result.current.data?.pages[0]?.announcements).toHaveLength(2)
    expect(result.current.data?.pages[0]?.announcements[0]?.title).toBe('Newer Announcement')
    expect(result.current.data?.pages[0]?.announcements[1]?.title).toBe('Older Announcement')

    cleanup()
  })

  it('should trust GraphQL API to return only visible announcements', async () => {
    // Mock API response that already has permissions filtering applied server-side
    const filteredAnnouncementResponse = {
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
                  title: 'Visible Announcement',
                  message: 'This announcement is visible to the user',
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
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserAnnouncements', () => {
        return HttpResponse.json(filteredAnnouncementResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    // The API should return only announcements the user can see
    expect(result.current.data?.pages).toHaveLength(1)
    expect(result.current.data?.pages[0]?.announcements).toHaveLength(1)
    expect(result.current.data?.pages[0]?.announcements[0]?.title).toBe('Visible Announcement')
    expect(result.current.error).toBeNull()

    cleanup()
  })
})
