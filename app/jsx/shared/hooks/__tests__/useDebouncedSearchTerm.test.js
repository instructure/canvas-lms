/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import useDebouncedSearchTerm from '../useDebouncedSearchTerm'

describe('useDebouncedSearchTerm', () => {
  beforeAll(() => {
    jest.useFakeTimers()
  })

  it('debounces updates to the searchTerm state', () => {
    const {result} = renderHook(() => useDebouncedSearchTerm('default'))
    act(() => result.current.setSearchTerm('updated'))
    expect(result.current.searchTerm).toBe('default')
    act(() => jest.runAllTimers())
    expect(result.current.searchTerm).toBe('updated')
  })

  it('does not update the search term when it is not searchable', () => {
    const isSearchableTerm = term => term === 'searchable'
    const {result} = renderHook(() => useDebouncedSearchTerm('default', {isSearchableTerm}))
    act(() => result.current.setSearchTerm('blah'))
    act(() => jest.runAllTimers())
    expect(result.current.searchTerm).toBe('default')
    act(() => result.current.setSearchTerm('searchable'))
    act(() => jest.runAllTimers())
    expect(result.current.searchTerm).toBe('searchable')
  })

  it('sets pending state as the search term change is scheduled and fulfilled', () => {
    const {result} = renderHook(() => useDebouncedSearchTerm('default'))
    expect(result.current.searchTermIsPending).toBe(false)
    act(() => result.current.setSearchTerm('updated'))
    expect(result.current.searchTermIsPending).toBe(true)
    act(() => jest.runAllTimers())
    expect(result.current.searchTermIsPending).toBe(false)
  })

  it('returns a method to cancel the search term change', () => {
    const {result} = renderHook(() => useDebouncedSearchTerm('default'))
    act(() => result.current.setSearchTerm('updated'))
    act(() => result.current.cancelCallback())
    act(() => jest.runAllTimers())
    expect(result.current.searchTerm).toBe('default')
    expect(result.current.searchTermIsPending).toBe(false)
  })

  it('returns a method to immediately update the search term', () => {
    const {result} = renderHook(() => useDebouncedSearchTerm('default'))
    act(() => result.current.setSearchTerm('updated'))
    act(() => result.current.callPending())
    expect(result.current.searchTerm).toBe('updated')
    expect(result.current.searchTermIsPending).toBe(false)
  })

  it('aborts the pending search if the search term reverts to its current value', () => {
    const {result} = renderHook(() => useDebouncedSearchTerm('default'))
    act(() => result.current.setSearchTerm('updated'))
    expect(result.current.searchTermIsPending).toBe(true)
    // and now set it back before the debounce happens, and pending should immediately become false
    act(() => result.current.setSearchTerm('default'))
    expect(result.current.searchTermIsPending).toBe(false)
  })
})
