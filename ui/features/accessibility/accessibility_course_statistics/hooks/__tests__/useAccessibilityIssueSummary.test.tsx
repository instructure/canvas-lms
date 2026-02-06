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

  const renderUseAccessibilityIssueSummary = () => {
    return renderHook(() => useAccessibilityIssueSummary({accountId}), {wrapper})
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

    const cachedData = queryClient.getQueryData(['accessibility-issue-summary', accountId])
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
