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

import {renderHook, act} from '@testing-library/react-hooks'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {useSearchTerm} from '../useSearchTerm'
import {generateSearchNavigationUrl} from '../../../utils/apiUtils'

vi.mock('../../../utils/apiUtils', () => ({
  generateSearchNavigationUrl: vi.fn(term => getExpectedSearchUrl(term)),
}))

vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useNavigate: vi.fn(),
}))

const getExpectedSearchUrl = (term: string) => `/search?search_term=${term}`
const getWrapper =
  (initialEntry: string) =>
  ({children}: {children: React.ReactNode}) => (
    <MemoryRouter initialEntries={[initialEntry]}>{children}</MemoryRouter>
  )

describe('useSearchTerm', () => {
  const expectedSearchTerm = 'new-term'
  let mockNavigate: ReturnType<typeof vi.fn>

  beforeEach(() => {
    mockNavigate = vi.fn()
    ;(useNavigate as ReturnType<typeof vi.fn>).mockReturnValue(mockNavigate)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('should return the current search term from the URL', () => {
    const {result} = renderHook(() => useSearchTerm(), {
      wrapper: getWrapper(`/?search_term=${expectedSearchTerm}`),
    })
    expect(result.current.searchTerm).toBe(expectedSearchTerm)
  })

  it('should return an empty string if no search term is present in the URL', () => {
    const {result} = renderHook(() => useSearchTerm(), {wrapper: getWrapper('/')})
    expect(result.current.searchTerm).toBe('')
  })

  it('should navigate to the correct URL when setSearchTerm is called', () => {
    const {result} = renderHook(() => useSearchTerm(), {wrapper: getWrapper('/')})
    act(() => {
      result.current.setSearchTerm(expectedSearchTerm)
    })

    expect(generateSearchNavigationUrl).toHaveBeenCalledWith(expectedSearchTerm)
    expect(mockNavigate).toHaveBeenCalledWith(getExpectedSearchUrl(expectedSearchTerm))
  })

  it('should encode the search term when navigating', () => {
    const specialTerm = 'test term with spaces & special characters'
    const encodedTerm = encodeURIComponent(specialTerm)
    const {result} = renderHook(() => useSearchTerm(), {wrapper: getWrapper('/')})

    act(() => {
      result.current.setSearchTerm(specialTerm)
    })

    expect(generateSearchNavigationUrl).toHaveBeenCalledWith(encodedTerm)
    expect(mockNavigate).toHaveBeenCalledWith(getExpectedSearchUrl(encodedTerm))
  })

  it('should return the URL-encoded search term', () => {
    const {result} = renderHook(() => useSearchTerm(), {
      wrapper: getWrapper(`/?search_term=${expectedSearchTerm}`),
    })
    expect(result.current.urlEncodedSearchTerm).toBe(encodeURIComponent(expectedSearchTerm))
  })
})
