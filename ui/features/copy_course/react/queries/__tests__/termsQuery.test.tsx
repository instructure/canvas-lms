/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {getTermsNextPage, termsQuery, useTermsQuery} from '../termsQuery'
import {useAllPages} from '@canvas/query'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import type {QueryFunctionContext} from '@tanstack/react-query'
import type {EnrollmentTerms} from '../../../../../api'

jest.mock('@canvas/query', () => ({
  useAllPages: jest.fn(),
}))
jest.mock('@canvas/do-fetch-api-effect')

describe('useTermsQuery', () => {
  const mockData: any = {
    pages: [
      {json: {enrollment_terms: [{id: 1, name: 'Term 1'}]}},
      {json: {enrollment_terms: [{id: 2, name: 'Term 2'}]}},
    ],
  }

  const mockUseAllPages = useAllPages as jest.Mock

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should return terms data', () => {
    mockUseAllPages.mockReturnValue({
      isLoading: false,
      isError: false,
      data: mockData,
    })

    const {result} = renderHook(() => useTermsQuery('accountId'))

    expect(result.current.data).toEqual([
      {id: 1, name: 'Term 1'},
      {id: 2, name: 'Term 2'},
    ])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.isError).toBe(false)
  })

  it('should handle loading state', () => {
    mockUseAllPages.mockReturnValue({
      isLoading: true,
      isError: false,
      data: null,
    })

    const {result} = renderHook(() => useTermsQuery('accountId'))

    expect(result.current.data).toEqual([])
    expect(result.current.isLoading).toBe(true)
    expect(result.current.isError).toBe(false)
  })

  it('should handle error state', () => {
    mockUseAllPages.mockReturnValue({
      isLoading: false,
      isError: true,
      data: null,
    })

    const {result} = renderHook(() => useTermsQuery('accountId'))

    expect(result.current.data).toEqual([])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.isError).toBe(true)
  })
})

describe('termsQuery', () => {
  const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

  it('should fetch terms with correct parameters', async () => {
    const mockResponse: any = {json: {enrollment_terms: []}, link: {}}
    mockDoFetchApi.mockResolvedValue(mockResponse)

    const context: QueryFunctionContext = {
      meta: undefined,
      signal: new AbortController().signal,
      queryKey: ['copy_course', 'enrollment_terms', '1'],
      pageParam: {page: '2', per_page: '20'},
    }

    const result = await termsQuery(context)

    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/accounts/1/terms?page=2&per_page=20',
      fetchOpts: {signal: context.signal},
    })
    expect(result).toEqual(mockResponse)
  })

  it('should use default page and per_page if pageParam is missing', async () => {
    const mockResponse: any = {json: {enrollment_terms: []}, link: {}}
    mockDoFetchApi.mockResolvedValue(mockResponse)

    const context: QueryFunctionContext = {
      meta: undefined,
      signal: new AbortController().signal,
      queryKey: ['copy_course', 'enrollment_terms', '1'],
      pageParam: undefined,
    }

    const result = await termsQuery(context)

    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/accounts/1/terms?page=1&per_page=10',
      fetchOpts: {signal: context.signal},
    })
    expect(result).toEqual(mockResponse)
  })
})

describe('getTermsNextPage', () => {
  it('should return the next page link if it exists', () => {
    const expectedNext = {page: '2', per_page: '10'}
    const lastPage: DoFetchApiResults<EnrollmentTerms> = {
      json: undefined,
      response: new Response(),
      text: '',
      link: {next: expectedNext},
    }
    const result = getTermsNextPage(lastPage)
    expect(result).toEqual(expectedNext)
  })

  it('should return undefined if there is no next page link', () => {
    const lastPage: DoFetchApiResults<EnrollmentTerms> = {
      json: undefined,
      response: new Response(),
      text: '',
      link: {},
    }
    const result = getTermsNextPage(lastPage)
    expect(result).toBeUndefined()
  })
})
