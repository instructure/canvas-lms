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
import useSearch from '../useSearch'
import {ChangeEvent} from 'react'

jest.useFakeTimers()

describe('useSearch', () => {
  const event = {
    target: {
      value: '123',
    }
  } as ChangeEvent<HTMLInputElement>

  it('should create custom hook with initial state an empty string', () => {
    const {result} = renderHook(() => useSearch())
    expect(result.current.search).toBe('')
  })

  it('should update state with event.target.value when first returned fn called with debounce disabled', () => {
    const {result} = renderHook(() => useSearch(0))
    act(() => {
      result.current.onChangeHandler(event)
    })
    expect(result.current.search).toBe('123')
    expect(result.current.debouncedSearch).toBe('')
    act(() => {
      jest.runAllTimers()
    })
    expect(result.current.debouncedSearch).toBe('123')
  })

  it('should clear state to empty string when second returned fn is called', () => {
    const {result} = renderHook(() => useSearch())
    act(() => {
      result.current.onClearHandler()
    })
    act(() => {
      jest.runAllTimers()
    })
    expect(result.current.search).toBe('')
  })

  it('should update state with event.target.value using default debounce', () => {
    const {result} = renderHook(() => useSearch())
    act(() => {
      result.current.onChangeHandler(event)
    })
    expect(result.current.search).toBe('123')
    expect(result.current.debouncedSearch).toBe('')
    act(() => {
      jest.advanceTimersByTime(100)
    })
    expect(result.current.debouncedSearch).toBe('')
    act(() => {
      jest.advanceTimersByTime(100)
    })
    expect(result.current.debouncedSearch).toBe('')
    act(() => {
      jest.advanceTimersByTime(300)
    })
    expect(result.current.debouncedSearch).toBe('123')
  })
})
