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

import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient} from '@tanstack/react-query'
import React from 'react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import doFetchApiModule from '@canvas/do-fetch-api-effect'
import {useCheckAllocationConversion} from '../useCheckAllocationConversion'

vi.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: vi.fn(),
}))

const doFetchApi = vi.mocked(doFetchApiModule)

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )
}

describe('useCheckAllocationConversion', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns hasLegacyAllocations true when API returns items', async () => {
    doFetchApi.mockResolvedValueOnce({
      response: {ok: true} as Response,
      json: [{id: 1}, {id: 2}],
      text: '',
      link: undefined,
    })

    const {result} = renderHook(() => useCheckAllocationConversion('1', '2', true), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.hasLegacyAllocations).toBe(true)
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/1/assignments/2/check_allocation_conversion',
    })
  })

  it('returns hasLegacyAllocations false when API returns empty array', async () => {
    doFetchApi.mockResolvedValueOnce({
      response: {ok: true} as Response,
      json: [],
      text: '',
      link: undefined,
    })

    const {result} = renderHook(() => useCheckAllocationConversion('1', '2', true), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.hasLegacyAllocations).toBe(false)
  })

  it('returns hasLegacyAllocations false when API returns null', async () => {
    doFetchApi.mockResolvedValueOnce({
      response: {ok: true} as Response,
      json: null,
      text: '',
      link: undefined,
    })

    const {result} = renderHook(() => useCheckAllocationConversion('1', '2', true), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.hasLegacyAllocations).toBe(false)
  })

  it('does not fetch when enabled is false', () => {
    renderHook(() => useCheckAllocationConversion('1', '2', false), {wrapper: createWrapper()})

    expect(doFetchApi).not.toHaveBeenCalled()
  })

  it('does not fetch when courseId is empty', () => {
    renderHook(() => useCheckAllocationConversion('', '2', true), {wrapper: createWrapper()})

    expect(doFetchApi).not.toHaveBeenCalled()
  })

  it('does not fetch when assignmentId is empty', () => {
    renderHook(() => useCheckAllocationConversion('1', '', true), {wrapper: createWrapper()})

    expect(doFetchApi).not.toHaveBeenCalled()
  })

  it('returns error when API call fails', async () => {
    doFetchApi.mockRejectedValueOnce(new Error('Network error'))

    const {result} = renderHook(() => useCheckAllocationConversion('1', '2', true), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.error).toBeTruthy()
    expect(result.current.hasLegacyAllocations).toBe(false)
  })
})
