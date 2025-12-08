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
import {useInboxMessages} from '../useInboxMessages'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockConversationResponse = {
  data: {
    legacyNode: {
      _id: '1',
      conversationsConnection: {
        nodes: [
          {
            conversation: {
              _id: '101',
              subject: 'Test Message 1',
              updatedAt: '2025-12-08T10:00:00Z',
              conversationMessagesConnection: {
                nodes: [
                  {
                    _id: 'msg1',
                    body: '<p>This is a test message</p>',
                    createdAt: '2025-12-08T10:00:00Z',
                    author: {
                      _id: '2',
                      name: 'John Doe',
                      avatarUrl: 'https://example.com/avatar.jpg',
                    },
                  },
                ],
              },
              conversationParticipantsConnection: {
                nodes: [
                  {
                    user: {
                      _id: '2',
                      name: 'John Doe',
                      avatarUrl: 'https://example.com/avatar.jpg',
                    },
                  },
                ],
              },
            },
            workflowState: 'unread',
          },
          {
            conversation: {
              _id: '102',
              subject: 'Test Message 2',
              updatedAt: '2025-12-07T14:30:00Z',
              conversationMessagesConnection: {
                nodes: [
                  {
                    _id: 'msg2',
                    body: 'Another test message',
                    createdAt: '2025-12-07T14:30:00Z',
                    author: {
                      _id: '3',
                      name: 'Jane Smith',
                      avatarUrl: null,
                    },
                  },
                ],
              },
              conversationParticipantsConnection: {
                nodes: [
                  {
                    user: {
                      _id: '3',
                      name: 'Jane Smith',
                      avatarUrl: null,
                    },
                  },
                ],
              },
            },
            workflowState: 'read',
          },
        ],
      },
    },
  },
}

const setup = (envOverrides = {}, options = {}) => {
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '1',
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

  const result = renderHook(() => useInboxMessages(options), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

  return {
    ...result,
    queryClient,
    cleanup: () => {
      window.ENV = originalEnv
      result.unmount()
    },
  }
}

const server = setupServer(
  graphql.query('GetUserConversations', () => {
    return HttpResponse.json(mockConversationResponse)
  }),
)

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  clearWidgetDashboardCache()
})
afterAll(() => server.close())

describe('useInboxMessages', () => {
  it('fetches and transforms inbox messages', async () => {
    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toHaveLength(2)
    expect(result.current.data?.[0]).toEqual({
      id: '101',
      subject: 'Test Message 1',
      lastMessageAt: '2025-12-08T10:00:00Z',
      messagePreview: 'This is a test message',
      workflowState: 'unread',
      conversationUrl: '/conversations/101',
      participants: [
        {
          id: '2',
          name: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
        },
      ],
    })

    cleanup()
  })

  it('handles unread filter', async () => {
    server.use(
      graphql.query('GetUserConversations', ({variables}) => {
        expect(variables.scope).toBe('unread')
        expect(variables.first).toBe(5)
        return HttpResponse.json(mockConversationResponse)
      }),
    )

    const {result, cleanup} = setup({}, {filter: 'unread'})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    cleanup()
  })

  it('handles all filter', async () => {
    server.use(
      graphql.query('GetUserConversations', ({variables}) => {
        expect(variables.scope).toBeUndefined()
        expect(variables.first).toBe(5)
        return HttpResponse.json(mockConversationResponse)
      }),
    )

    const {result, cleanup} = setup({}, {filter: 'all'})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    cleanup()
  })

  it('returns empty array when no conversations exist', async () => {
    server.use(
      graphql.query('GetUserConversations', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              conversationsConnection: {
                nodes: [],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toEqual([])

    cleanup()
  })

  it('handles GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserConversations', () => {
        return HttpResponse.json({errors: [{message: 'GraphQL error'}]}, {status: 500})
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(result.current.error).toBeTruthy()

    cleanup()
  })

  it('strips HTML tags from message preview', async () => {
    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data?.[0].messagePreview).toBe('This is a test message')
    expect(result.current.data?.[0].messagePreview).not.toContain('<p>')

    cleanup()
  })

  it('truncates long message previews', async () => {
    const longMessage = 'A'.repeat(100)
    server.use(
      graphql.query('GetUserConversations', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              conversationsConnection: {
                nodes: [
                  {
                    conversation: {
                      _id: '101',
                      subject: 'Test',
                      updatedAt: '2025-12-08T10:00:00Z',
                      conversationMessagesConnection: {
                        nodes: [
                          {
                            _id: 'msg1',
                            body: longMessage,
                            createdAt: '2025-12-08T10:00:00Z',
                            author: {
                              _id: '2',
                              name: 'John Doe',
                              avatarUrl: null,
                            },
                          },
                        ],
                      },
                      conversationParticipantsConnection: {
                        nodes: [
                          {
                            user: {
                              _id: '2',
                              name: 'John Doe',
                              avatarUrl: null,
                            },
                          },
                        ],
                      },
                    },
                    workflowState: 'unread',
                  },
                ],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data?.[0].messagePreview).toHaveLength(83)
    expect(result.current.data?.[0].messagePreview.endsWith('...')).toBe(true)

    cleanup()
  })

  it('handles missing current user ID', async () => {
    const {result, cleanup} = setup({current_user_id: undefined})

    expect(result.current.data).toBeUndefined()
    expect(result.current.isPending).toBe(true)

    cleanup()
  })

  it('uses default subject when subject is null', async () => {
    server.use(
      graphql.query('GetUserConversations', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              conversationsConnection: {
                nodes: [
                  {
                    conversation: {
                      _id: '101',
                      subject: null,
                      updatedAt: '2025-12-08T10:00:00Z',
                      conversationMessagesConnection: {
                        nodes: [
                          {
                            _id: 'msg1',
                            body: 'Test',
                            createdAt: '2025-12-08T10:00:00Z',
                            author: {
                              _id: '2',
                              name: 'John Doe',
                              avatarUrl: null,
                            },
                          },
                        ],
                      },
                      conversationParticipantsConnection: {
                        nodes: [],
                      },
                    },
                    workflowState: 'unread',
                  },
                ],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data?.[0].subject).toBe('(No subject)')

    cleanup()
  })
})
