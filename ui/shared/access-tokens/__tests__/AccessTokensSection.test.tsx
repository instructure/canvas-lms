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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {type MockedFunction} from 'vitest'
import {AccessTokensSection} from '../AccessTokensSection'
import {ZTokenId, type Token} from '../Token'
import {ZUserId} from '../UserId'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'

const mockConfirmDanger = confirmDanger as MockedFunction<typeof confirmDanger>

vi.mock('@canvas/instui-bindings/react/Confirm', () => ({
  confirmDanger: vi.fn(),
}))

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

// Mock TruncateText component, we don't need to test that
// it truncates text correctly
vi.mock('@instructure/ui-truncate-text', () => {
  return {
    TruncateText: ({children}: React.PropsWithChildren) => children,
  }
})

const mockTokens: Token[] = [
  {
    id: ZTokenId.parse('1'),
    user_id: ZUserId.parse('123'),
    purpose: 'Test Token 1',
    created_at: '2025-01-01T10:00:00Z',
    updated_at: '2025-01-01T10:00:00Z',
    expires_at: '2025-12-31T23:59:59Z',
    last_used_at: '2025-04-01T10:00:00Z',
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

const defaultHandlers = [
  http.get('/api/v1/users/123/user_generated_tokens', () => {
    return HttpResponse.json(mockTokens)
  }),
  http.delete('/api/v1/users/123/tokens/:tokenId', () => {
    console.log('Mock delete handler called')
    return HttpResponse.json({})
  }),
]

export const server = setupServer(...defaultHandlers)

beforeAll(() => server.listen({onUnhandledRequest: 'error'}))
afterEach(() => {
  vi.clearAllMocks()
  server.resetHandlers()
})
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

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = createQueryClient()
  return render(<QueryClientProvider client={queryClient}>{component}</QueryClientProvider>)
}

describe('AccessTokensSection', () => {
  const userId = ZUserId.parse('123')
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders tokens table when data is loaded', async () => {
    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(
        screen.getByText('These are the access tokens this user has generated to access Canvas:'),
      ).toBeInTheDocument()
    })

    expect(screen.getByText('abc123')).toBeInTheDocument()
    expect(screen.getByText('Test Token 1')).toBeInTheDocument()
    expect(screen.getByText('Test Token 2')).toBeInTheDocument()
    expect(screen.getByText(/Jan 1, 2025/)).toBeInTheDocument()
    expect(screen.getByText(/Jan 2, 2025/)).toBeInTheDocument()
    expect(screen.getByText(/Dec 31, 2025/)).toBeInTheDocument()
    expect(screen.getByText('Never')).toBeInTheDocument()
    expect(screen.getByText('Unused')).toBeInTheDocument()
  })

  it('renders table headers correctly', async () => {
    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('ID')).toBeInTheDocument()
      expect(screen.getByText('Token')).toBeInTheDocument()
      expect(screen.getByText('Purpose')).toBeInTheDocument()
    })

    expect(screen.getByText('Created')).toBeInTheDocument()
    expect(screen.getByText('Expires')).toBeInTheDocument()
    expect(screen.getByText('Remove')).toBeInTheDocument()
  })

  it('renders delete buttons for each token', async () => {
    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('Delete Test Token 1 Token')).toBeInTheDocument()
    })

    expect(screen.getByText('Delete Test Token 2 Token')).toBeInTheDocument()
  })

  it('renders empty state when no tokens exist', async () => {
    server.use(
      http.get('/api/v1/users/123/user_generated_tokens', () => {
        return HttpResponse.json([])
      }),
    )

    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('This user has not generated any access tokens.')).toBeInTheDocument()
    })

    expect(screen.queryByRole('table')).not.toBeInTheDocument()
  })

  it('renders error state when API call fails', async () => {
    server.use(
      http.get('/api/v1/users/123/user_generated_tokens', () => {
        return HttpResponse.error()
      }),
    )

    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('Failed to load access tokens')).toBeInTheDocument()
    })
  })

  it('handles paginating tokens properly', async () => {
    const user = userEvent.setup()

    server.use(
      http.get('/api/v1/users/123/user_generated_tokens', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')

        if (page === '2') {
          return HttpResponse.json([])
        }

        return HttpResponse.json(mockTokens, {
          headers: {
            Link: '</api/v1/users/123/user_generated_tokens?page=2>; rel="next"',
          },
        })
      }),
    )

    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('Show More')).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', {name: 'Show More'}))

    await waitFor(() => {
      expect(screen.queryByText('Show More')).not.toBeInTheDocument()
    })
  })

  it('does not delete token when user cancels confirmation', async () => {
    const user = userEvent.setup()
    mockConfirmDanger.mockResolvedValue(false)

    renderWithQueryClient(<AccessTokensSection userId={userId} />)

    await waitFor(() => {
      expect(screen.getByText('Delete Test Token 1 Token')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Delete Test Token 1 Token')!.closest('button')!)

    expect(mockConfirmDanger).toHaveBeenCalledTimes(1)

    // Token should still be visible since deletion was cancelled
    expect(screen.getByText('Test Token 1')).toBeInTheDocument()
    expect(screen.getByText('Test Token 2')).toBeInTheDocument()
  })
})
