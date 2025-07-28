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
import {renderHook} from '@testing-library/react-hooks'
import fetchMock from 'fetch-mock'
import {useGetPaginatedFiles} from '../useGetPaginatedFiles'
import {useSearchTerm} from '../useSearchTerm'
import {queryClient} from '@canvas/query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'

jest.mock('../useSearchTerm')
const mockGenerateTableUrl = jest.fn()
jest.mock('../../../utils/apiUtils', () => ({
  ...jest.requireActual('../../../utils/apiUtils'),
  parseLinkHeader: jest.fn(() => ({next: 'next-link'})),
  parseBookmarkFromUrl: jest.fn(() => 'bookmark'),
  generateTableUrl: (params: any) => {
    mockGenerateTableUrl(params)
    return 'generated-url'
  },
  UnauthorizedError: class UnauthorizedError extends Error {},
}))

describe('useGetPaginatedFiles', () => {
  const mockFolder = {
    id: '1',
    name: 'Test Folder',
    context_id: '1',
    context_type: 'Course',
  }

  const mockOnSettled = jest.fn()
  const mockSetSearchTerm = jest.fn()

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )

  beforeEach(() => {
    jest.clearAllMocks()
    fetchMock.reset()
    fetchMock.mock('*', {
      body: [{id: '1', name: 'test.txt'}],
      headers: {
        Link: '<https://canvas.example.com/api/v1/courses/1/files?bookmark=next>; rel="next"',
      },
    })
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm: '',
      setSearchTerm: mockSetSearchTerm,
    }))
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('returns all results when search term is empty', async () => {
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm: '',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()
    expect(fetchMock.called()).toBe(true)
    expect(mockOnSettled).toHaveBeenCalled()
    expect(result.current.data).toBeTruthy()
  })

  it('returns empty results when search term is a single character without making API call', async () => {
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm: 'a',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(result.current.search.term).toBe('a')
    expect(mockOnSettled).toHaveBeenCalledWith([])
    expect(fetchMock.called()).toBe(false)
    expect(result.current.data).toEqual([])
  })

  it('handles search terms with more than one character', async () => {
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm: 'test',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(mockGenerateTableUrl).toHaveBeenCalled()
    expect(fetchMock.called()).toBe(true)
    expect(mockOnSettled).toHaveBeenCalled()
    expect(result.current.data).toBeTruthy()
  })

  it('handles search terms with spaces correctly', async () => {
    // Setup search term with a space and a character (should be treated as single char)
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm: ' a ',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(fetchMock.called()).toBe(false)
    expect(mockOnSettled).toHaveBeenCalledWith([])
    expect(result.current.data).toEqual([])
  })

  it('calls backend with URL-encoded search term', async () => {
    const searchTerm = '!@#$%^&*()_+'
    const expectedEncodedTerm = encodeURIComponent(searchTerm)
    ;(useSearchTerm as jest.Mock).mockImplementation(() => ({
      searchTerm,
      urlEncodedSearchTerm: expectedEncodedTerm,
      setSearchTerm: mockSetSearchTerm,
    }))

    const {waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(mockGenerateTableUrl).toHaveBeenCalledWith(
      expect.objectContaining({
        contextId: mockFolder.context_id,
        contextType: mockFolder.context_type.toLowerCase(),
        folderId: mockFolder.id.toString(),
        searchTerm: expectedEncodedTerm,
      }),
    )
  })
})
