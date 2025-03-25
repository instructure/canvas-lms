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

import { renderHook, act } from '@testing-library/react-hooks'
import { MemoryRouter, useNavigate } from 'react-router-dom'
import { useSearchTerm } from '../useSearchTerm'
import { generateSearchNavigationUrl } from '../../../utils/apiUtils'

jest.mock('../../../utils/apiUtils', () => ({
  generateSearchNavigationUrl: jest.fn((term) => getExpectedSearchUrl(term)),
}))

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}))

const getExpectedSearchUrl = (term: string) => `/search?search_term=${term}`
const getWrapper = (initialEntry: string) => ({ children }: { children: React.ReactNode }) => (
  <MemoryRouter initialEntries={[initialEntry]}>{children}</MemoryRouter>
)

describe('useSearchTerm', () => {
  const expectedSearchTerm = 'new-term'
  let mockNavigate: jest.Mock

  beforeEach(() => {
    mockNavigate = jest.fn()
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should return the current search term from the URL', () => {
    const { result } = renderHook(() => useSearchTerm(), { wrapper: getWrapper(`/?search_term=${expectedSearchTerm}`) })
    expect(result.current.searchTerm).toBe(expectedSearchTerm)
  })

  it('should return an empty string if no search term is present in the URL', () => {
    const { result } = renderHook(() => useSearchTerm(), { wrapper: getWrapper('/') })
    expect(result.current.searchTerm).toBe('')
  })

  it('should navigate to the correct URL when setSearchTerm is called', () => {
    const { result } = renderHook(() => useSearchTerm(), { wrapper: getWrapper('/') })
    act(() => {
      result.current.setSearchTerm(expectedSearchTerm)
    })

    expect(generateSearchNavigationUrl).toHaveBeenCalledWith(expectedSearchTerm)
    expect(mockNavigate).toHaveBeenCalledWith(getExpectedSearchUrl(expectedSearchTerm))
  })
})
