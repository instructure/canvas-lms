/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useAccessibilityIssueSummary} from '../useAccessibilityIssueSummary'
import type {AccessibilityIssueSummary} from '../../types/accessibility_issue_summary'

const server = setupServer()
const accountId = '123'

describe('useAccessibilityIssueSummary', () => {
  let queryClient: QueryClient

  beforeAll(() => server.listen())

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  afterAll(() => server.close())

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  const renderUseAccessibilityIssueSummary = (enrollmentTermId?: string) => {
    return renderHook(() => useAccessibilityIssueSummary({accountId, enrollmentTermId}), {wrapper})
  }

  it('fetches accessibility issue summary successfully', async () => {
    const mockSummary: AccessibilityIssueSummary = {
      active: 42,
      resolved: 128,
    }

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        return HttpResponse.json(mockSummary)
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data).toEqual(mockSummary)
    expect(result.current.data?.active).toBe(42)
    expect(result.current.data?.resolved).toBe(128)
  })

  it('handles empty response with default values', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        return HttpResponse.json(null)
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data).toEqual({active: 0, resolved: 0})
  })

  it('uses correct API endpoint with account ID', async () => {
    const mockSummary: AccessibilityIssueSummary = {active: 10, resolved: 5}
    let requestUrl = ''

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, ({request}) => {
        requestUrl = request.url
        return HttpResponse.json(mockSummary)
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(requestUrl).toContain(`/api/v1/accounts/${accountId}/accessibility_issue_summary`)
  })

  it('includes account ID in query key for proper caching', async () => {
    const mockSummary: AccessibilityIssueSummary = {active: 15, resolved: 30}

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        return HttpResponse.json(mockSummary)
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const cachedData = queryClient.getQueryData([
      'accessibility-issue-summary',
      accountId,
      undefined,
    ])
    expect(cachedData).toEqual(mockSummary)
  })

  it('handles API errors gracefully', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        return HttpResponse.json({error: 'Internal Server Error'}, {status: 500})
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isError).toBe(true))

    expect(result.current.data).toBeUndefined()
  })

  it('sends enrollment_term_id param when provided', async () => {
    let params: URLSearchParams | undefined

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, ({request}) => {
        params = new URL(request.url).searchParams
        return HttpResponse.json({active: 4, resolved: 2})
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary('42')

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(params?.get('enrollment_term_id')).toBe('42')
  })

  it('omits enrollment_term_id param when not provided', async () => {
    let params: URLSearchParams | undefined

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, ({request}) => {
        params = new URL(request.url).searchParams
        return HttpResponse.json({active: 0, resolved: 0})
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(params?.has('enrollment_term_id')).toBe(false)
  })

  it('includes enrollmentTermId in query key for per-term caching', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () =>
        HttpResponse.json({active: 4, resolved: 2}),
      ),
    )

    const {result} = renderUseAccessibilityIssueSummary('42')

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const cachedData = queryClient.getQueryData(['accessibility-issue-summary', accountId, '42'])
    expect(cachedData).toEqual({active: 4, resolved: 2})
  })

  it('refetches when enrollmentTermId changes', async () => {
    let requestCount = 0

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        requestCount++
        return HttpResponse.json({active: requestCount, resolved: 0})
      }),
    )

    const localWrapper = ({children}: React.PropsWithChildren<{termId?: string}>) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )

    const {result, rerender} = renderHook(
      ({termId}: {termId?: string}) =>
        useAccessibilityIssueSummary({accountId, enrollmentTermId: termId}),
      {wrapper: localWrapper, initialProps: {termId: undefined} as {termId?: string}},
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(requestCount).toBe(1)

    rerender({termId: '42'})

    await waitFor(() => expect(result.current.data?.active).toBe(2))
    expect(requestCount).toBe(2)
  })

  it('returns zero values when summary has zero counts', async () => {
    const mockSummary: AccessibilityIssueSummary = {
      active: 0,
      resolved: 0,
    }

    server.use(
      http.get(`/api/v1/accounts/${accountId}/accessibility_issue_summary`, () => {
        return HttpResponse.json(mockSummary)
      }),
    )

    const {result} = renderUseAccessibilityIssueSummary()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.active).toBe(0)
    expect(result.current.data?.resolved).toBe(0)
  })
})
