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

import type React from 'react'
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {useManuallyGeneratedTokens, useDeleteToken} from '../api'
import {ZTokenId, type Token} from '../Token'
import {ZUserId} from '../UserId'
import {renderHook} from '@testing-library/react-hooks'

const mockShowFlashAlert = vi.fn()

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: mockShowFlashAlert,
}))

const mockTokens: Token[] = [
  {
    id: ZTokenId.parse('1'),
    user_id: ZUserId.parse('123'),
    purpose: 'Test Token 1',
    created_at: '2025-01-01T10:00:00Z',
    updated_at: '2025-01-01T10:00:00Z',
    expires_at: '2025-12-31T23:59:59Z',
    last_used_at: null,
    scopes: [],
    remember_access: null,
    workflow_state: 'active',
    real_user_id: null,
    app_name: 'User Generated',
    visible_token: 'abc123',
    can_manually_regenerate: true,
  },
  {
    id: ZTokenId.parse('2'),
    user_id: ZUserId.parse('123'),
    purpose: 'Test Token 2',
    created_at: '2025-01-02T10:00:00Z',
    updated_at: '2025-01-02T10:00:00Z',
    last_used_at: null,
    expires_at: null,
    scopes: [],
    remember_access: null,
    workflow_state: 'active',
    real_user_id: null,
    app_name: 'User Generated',
    visible_token: 'def456',
    can_manually_regenerate: true,
  },
]

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
      mutations: {
        retry: false,
      },
    },
  })

const createWrapper = () => {
  const queryClient = createQueryClient()
  return function Wrapper({children}: {children: React.ReactNode}) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  }
}

describe('useTokens', () => {
  const userId = ZUserId.parse('123')

  it('fetches tokens successfully', async () => {
    server.use(
      http.get('/api/v1/users/123/user_generated_tokens', () => {
        return HttpResponse.json(mockTokens)
      }),
    )

    const {result} = renderHook(() => useManuallyGeneratedTokens(userId), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data?.pages).toHaveLength(1)
    expect(result.current.data?.pages[0].json).toEqual(mockTokens)
  })

  it('handles pagination with link headers', async () => {
    server.use(
      http.get('/api/v1/users/123/user_generated_tokens', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')

        if (page === '2') {
          return HttpResponse.json([mockTokens[1]], {
            headers: {
              Link: '</api/v1/users/123/user_generated_tokens?page=1>; rel="prev"',
            },
          })
        }

        return HttpResponse.json([mockTokens[0]], {
          headers: {
            Link: '</api/v1/users/123/user_generated_tokens?page=2>; rel="next"',
          },
        })
      }),
    )

    const {result} = renderHook(() => useManuallyGeneratedTokens(userId), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.hasNextPage).toBe(true)

    result.current.fetchNextPage()

    await waitFor(() => {
      expect(result.current.data?.pages).toHaveLength(2)
    })

    expect(result.current.data?.pages[0].json).toEqual([mockTokens[0]])
    expect(result.current.data?.pages[1].json).toEqual([mockTokens[1]])
    expect(result.current.hasNextPage).toBe(false)
  })
})
