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
import {useTerms} from '../useTerms'

const server = setupServer()
const accountId = '123'

// Dates relative to "now" used across tests
const FUTURE_DATE = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
const PAST_DATE = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

describe('useTerms', () => {
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

  const renderUseTerms = (id = accountId) => renderHook(() => useTerms(id), {wrapper})

  it('fetches terms and groups them as active, future, and past', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '1',
              name: 'Active Term',
              start_at: PAST_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
            {
              id: '2',
              name: 'Future Term',
              start_at: FUTURE_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
            {
              id: '3',
              name: 'Past Term',
              start_at: null,
              end_at: PAST_DATE,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => {
      expect(result.current.activeTerms.length).toBeGreaterThan(0)
    })

    expect(result.current.activeTerms).toHaveLength(1)
    expect(result.current.activeTerms[0].name).toBe('Active Term')

    expect(result.current.futureTerms).toHaveLength(1)
    expect(result.current.futureTerms[0].name).toBe('Future Term')

    expect(result.current.pastTerms).toHaveLength(1)
    expect(result.current.pastTerms[0].name).toBe('Past Term')
  })

  it('places a term with start_at in the future into futureTerms', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '10',
              name: 'Upcoming Term',
              start_at: FUTURE_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.futureTerms).toHaveLength(1)
    expect(result.current.futureTerms[0].id).toBe('10')
    expect(result.current.activeTerms).toHaveLength(0)
    expect(result.current.pastTerms).toHaveLength(0)
  })

  it('places a term with end_at in the past into pastTerms', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '20',
              name: 'Old Term',
              start_at: null,
              end_at: PAST_DATE,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.pastTerms).toHaveLength(1)
    expect(result.current.pastTerms[0].id).toBe('20')
    expect(result.current.activeTerms).toHaveLength(0)
    expect(result.current.futureTerms).toHaveLength(0)
  })

  it('places a term with no dates into activeTerms', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '30',
              name: 'Timeless Term',
              start_at: null,
              end_at: null,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.activeTerms).toHaveLength(1)
    expect(result.current.activeTerms[0].id).toBe('30')
    expect(result.current.futureTerms).toHaveLength(0)
    expect(result.current.pastTerms).toHaveLength(0)
  })

  it('places a term whose start_at is in the past and end_at is in the future into activeTerms', async () => {
    const FUTURE_END = new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString()

    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '40',
              name: 'Current Term',
              start_at: PAST_DATE,
              end_at: FUTURE_END,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.activeTerms).toHaveLength(1)
    expect(result.current.activeTerms[0].id).toBe('40')
    expect(result.current.futureTerms).toHaveLength(0)
    expect(result.current.pastTerms).toHaveLength(0)
  })

  it('returns empty arrays for all groups when no terms exist', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({enrollment_terms: []})
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.activeTerms).toEqual([])
    expect(result.current.futureTerms).toEqual([])
    expect(result.current.pastTerms).toEqual([])
  })

  it('does not fetch when accountId is empty', () => {
    let requestMade = false
    server.use(
      http.get(`/api/v1/accounts//terms`, () => {
        requestMade = true
        return HttpResponse.json({enrollment_terms: []})
      }),
    )

    const {result} = renderUseTerms('')

    // isLoading is false because the query is disabled, not pending
    expect(result.current.isLoading).toBe(false)
    expect(requestMade).toBe(false)
  })

  it('isLoading is true while fetching terms', () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, async () => {
        await new Promise(resolve => setTimeout(resolve, 200))
        return HttpResponse.json({enrollment_terms: []})
      }),
    )

    const {result} = renderUseTerms()

    expect(result.current.isLoading).toBe(true)
    expect(result.current.activeTerms).toEqual([])
    expect(result.current.futureTerms).toEqual([])
    expect(result.current.pastTerms).toEqual([])
  })

  it('normalises term ids to strings', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            // API may return numeric ids
            {
              id: 99,
              name: 'Numeric ID Term',
              start_at: null,
              end_at: null,
              used_in_subaccount: true,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.activeTerms[0].id).toBe('99')
  })

  it('excludes terms where used_in_subaccount is false', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () => {
        return HttpResponse.json({
          enrollment_terms: [
            {
              id: '1',
              name: 'Used Term',
              start_at: PAST_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
            {
              id: '2',
              name: 'Unused Term',
              start_at: PAST_DATE,
              end_at: null,
              used_in_subaccount: false,
            },
          ],
        })
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.activeTerms).toHaveLength(1)
    expect(result.current.activeTerms[0].name).toBe('Used Term')
  })

  it('sends per_page=100 and subaccount_id in the first request', async () => {
    let requestParams: URLSearchParams | undefined

    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, ({request}) => {
        requestParams = new URL(request.url).searchParams
        return HttpResponse.json({enrollment_terms: []})
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(requestParams?.get('per_page')).toBe('100')
    expect(requestParams?.get('subaccount_id')).toBe(accountId)
  })

  it('fetches all pages when the API returns a next link', async () => {
    const page2Url = `/api/v1/accounts/${accountId}/terms?page=2&per_page=100`

    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('page') === '2') {
          return HttpResponse.json(
            {
              enrollment_terms: [
                {
                  id: '2',
                  name: 'Page Two Term',
                  start_at: null,
                  end_at: null,
                  used_in_subaccount: true,
                },
              ],
            },
            {headers: {}},
          )
        }
        return HttpResponse.json(
          {
            enrollment_terms: [
              {
                id: '1',
                name: 'Page One Term',
                start_at: null,
                end_at: null,
                used_in_subaccount: true,
              },
            ],
          },
          {headers: {Link: `<http://localhost${page2Url}>; rel="next"`}},
        )
      }),
    )

    const {result} = renderUseTerms()

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    const allTerms = [
      ...result.current.activeTerms,
      ...result.current.futureTerms,
      ...result.current.pastTerms,
    ]
    expect(allTerms).toHaveLength(2)
    expect(allTerms.map(t => t.name)).toEqual(
      expect.arrayContaining(['Page One Term', 'Page Two Term']),
    )
  })
})
