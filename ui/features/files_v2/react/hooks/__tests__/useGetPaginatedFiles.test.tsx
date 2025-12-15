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
import {useGetPaginatedFiles} from '../useGetPaginatedFiles'
import {useSearchTerm} from '../useSearchTerm'
import {queryClient} from '@canvas/query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

vi.mock('../useSearchTerm')
const mockGenerateTableUrl = vi.fn()
vi.mock('../../../utils/apiUtils', async () => ({
  ...await vi.importActual('../../../utils/apiUtils'),
  parseLinkHeader: vi.fn(() => ({next: 'next-link'})),
  parseBookmarkFromUrl: vi.fn(() => 'bookmark'),
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

  const mockOnSettled = vi.fn()
  const mockSetSearchTerm = vi.fn()

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    vi.clearAllMocks()
    server.use(
      http.get('*', () => {
        return HttpResponse.json([{id: '1', name: 'test.txt'}], {
          headers: {
            Link: '<https://canvas.example.com/api/v1/courses/1/files?bookmark=next>; rel="next"',
          },
        })
      }),
    )
    vi.mocked(useSearchTerm).mockImplementation(() => ({
      searchTerm: '',
      urlEncodedSearchTerm: '',
      setSearchTerm: mockSetSearchTerm,
    }))
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('returns all results when search term is empty', async () => {
    vi.mocked(useSearchTerm).mockImplementation(() => ({
      searchTerm: '',
      urlEncodedSearchTerm: '',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()
    expect(mockOnSettled).toHaveBeenCalled()
    expect(result.current.data).toBeTruthy()
  })

  it('returns empty results when search term is a single character without making API call', async () => {
    vi.mocked(useSearchTerm).mockImplementation(() => ({
      searchTerm: 'a',
      urlEncodedSearchTerm: 'a',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(result.current.search.term).toBe('a')
    expect(mockOnSettled).toHaveBeenCalledWith([])
    expect(result.current.data).toEqual([])
  })

  it('handles search terms with more than one character', async () => {
    vi.mocked(useSearchTerm).mockImplementation(() => ({
      searchTerm: 'test',
      urlEncodedSearchTerm: 'test',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(mockGenerateTableUrl).toHaveBeenCalled()
    expect(mockOnSettled).toHaveBeenCalled()
    expect(result.current.data).toBeTruthy()
  })

  it('handles search terms with spaces correctly', async () => {
    // Setup search term with a space and a character (should be treated as single char)
    vi.mocked(useSearchTerm).mockImplementation(() => ({
      searchTerm: ' a ',
      urlEncodedSearchTerm: '%20a%20',
      setSearchTerm: mockSetSearchTerm,
    }))

    const {result, waitForNextUpdate} = renderHook(
      () => useGetPaginatedFiles({folder: mockFolder as any, onSettled: mockOnSettled}),
      {wrapper},
    )
    await waitForNextUpdate()

    expect(mockOnSettled).toHaveBeenCalledWith([])
    expect(result.current.data).toEqual([])
  })

  it('calls backend with URL-encoded search term', async () => {
    const searchTerm = '!@#$%^&*()_+'
    const expectedEncodedTerm = encodeURIComponent(searchTerm)
    vi.mocked(useSearchTerm).mockImplementation(() => ({
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
