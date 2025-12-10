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
import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useUtidMatching, type ApiRegistration} from '../useUtidMatching'

const server = setupServer()

const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})

const wrapper = ({children}: {children: React.ReactNode}) => (
  <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
)

describe('useUtidMatching', () => {
  const accountId = '123'
  const mockMatches: ApiRegistration[] = [
    {
      unified_tool_id: '550e8400-e29b-41d4-a716-446655440000',
      global_product_id: 'e8f9a0b1-c2d3-4567-e890-123456789abc',
      tool_name: 'Math Learning Platform',
      tool_id: 789,
      company_id: 456,
      company_name: 'Educational Tech Solutions',
      source: 'partner_provided',
    },
    {
      unified_tool_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
      global_product_id: 'd7e8f9a0-b1c2-4345-d678-90abcdef1234',
      tool_name: 'Science Lab Simulator',
      tool_id: 321,
      company_id: 654,
      company_name: 'STEM Education Corp',
      source: 'manual',
    },
  ]

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.clearAllMocks()
    jest.useFakeTimers()
  })

  afterEach(() => {
    server.resetHandlers()
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
    queryClient.clear()
  })

  it('returns empty matches initially', () => {
    const {result} = renderHook(() => useUtidMatching('', accountId), {wrapper})

    expect(result.current.matches).toEqual([])
    expect(result.current.loading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('fetches matches for valid redirect URIs after debounce', async () => {
    let capturedUrl = ''
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json({api_registrations: mockMatches})
      }),
    )

    const redirectUris = 'https://example.com/redirect\nhttps://another.com/callback'
    const {result} = renderHook(() => useUtidMatching(redirectUris, accountId), {wrapper})
    expect(result.current.loading).toBe(true)

    jest.advanceTimersByTime(500)
    await waitFor(
      () => {
        expect(result.current.loading).toBe(false)
      },
      {timeout: 3000},
    )

    expect(capturedUrl).toContain(`/api/v1/accounts/${accountId}/developer_keys/lookup_utids`)
    expect(result.current.matches).toEqual(mockMatches)
    expect(result.current.error).toBeNull()
  })

  it('handles empty response gracefully', async () => {
    // Use real timers for this test to avoid fake timer + MSW timing issues in CI
    jest.useRealTimers()

    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', () =>
        HttpResponse.json({api_registrations: []}),
      ),
    )

    const redirectUris = 'https://example.com/redirect'
    const {result} = renderHook(() => useUtidMatching(redirectUris, accountId), {wrapper})

    await waitFor(
      () => {
        expect(result.current.loading).toBe(false)
      },
      {timeout: 3000},
    )

    expect(result.current.matches).toEqual([])
    expect(result.current.error).toBeNull()
  })

  it('handles API errors', async () => {
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', () =>
        HttpResponse.error(),
      ),
    )

    const redirectUris = 'https://example.com/redirect'
    const {result} = renderHook(() => useUtidMatching(redirectUris, accountId), {wrapper})

    await waitFor(
      () => {
        expect(result.current.loading).toBe(false)
        expect(result.current.matches).toEqual([])
        expect(result.current.error).toBe('Failed to fetch matching products')
      },
      {timeout: 3000},
    )
  })

  it('does not make API call for empty redirect URIs', () => {
    let requestMade = false
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', () => {
        requestMade = true
        return HttpResponse.json({api_registrations: []})
      }),
    )

    renderHook(() => useUtidMatching('', accountId), {wrapper})

    jest.advanceTimersByTime(500)

    expect(requestMade).toBe(false)
  })

  it('does not make API call for whitespace-only redirect URIs', () => {
    let requestMade = false
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', () => {
        requestMade = true
        return HttpResponse.json({api_registrations: []})
      }),
    )

    renderHook(() => useUtidMatching('   \n  \n  ', accountId), {wrapper})

    jest.advanceTimersByTime(500)

    expect(requestMade).toBe(false)
  })

  it('debounces multiple rapid changes', async () => {
    let requestCount = 0
    let lastCapturedUrl = ''
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', ({request}) => {
        requestCount++
        lastCapturedUrl = request.url
        return HttpResponse.json({api_registrations: mockMatches})
      }),
    )

    const {rerender} = renderHook<{uris: string}, ReturnType<typeof useUtidMatching>>(
      ({uris}) => useUtidMatching(uris, accountId),
      {
        initialProps: {uris: 'https://example1.com'},
        wrapper: wrapper as any,
      },
    )

    // Rapid changes
    rerender({uris: 'https://example2.com'})
    jest.advanceTimersByTime(100)

    rerender({uris: 'https://example3.com'})
    jest.advanceTimersByTime(100)

    rerender({uris: 'https://example4.com'})
    jest.advanceTimersByTime(100)

    // Only the last call should be made after full debounce period
    jest.advanceTimersByTime(500)

    await waitFor(
      () => {
        expect(requestCount).toBe(2)
        expect(lastCapturedUrl).toContain('example4.com')
      },
      {timeout: 3000},
    )
  })

  it('trims and filters empty lines from redirect URIs', async () => {
    let capturedUrl = ''
    server.use(
      http.get('/api/v1/accounts/:accountId/developer_keys/lookup_utids', ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json({api_registrations: mockMatches})
      }),
    )

    const redirectUris = '  https://example.com  \n\n  https://another.com  \n  \n'
    const {result} = renderHook(() => useUtidMatching(redirectUris, accountId), {wrapper})

    jest.advanceTimersByTime(500)

    await waitFor(
      () => {
        expect(result.current.loading).toBe(false)
      },
      {timeout: 3000},
    )

    expect(capturedUrl).toContain('example.com')
    expect(capturedUrl).toContain('another.com')
  })
})
