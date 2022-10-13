/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import useSearch from '../useSearch'

jest.useFakeTimers()

describe('useSearch', () => {
  const event = {
    target: {
      value: '123',
    },
  }

  test('should create custom hook with initial state an empty string', () => {
    const {result} = renderHook(() => useSearch())
    expect(result.current.search).toBe('')
  })

  test('should update state with event.target.value when first returned fn called with debounce disabled', async () => {
    const {result} = renderHook(() => useSearch(0))
    act(() => result.current.onChangeHandler(event))
    expect(result.current.search).toBe('123')
    expect(result.current.debouncedSearch).toBe('')
    await act(async () => jest.runAllTimers())
    expect(result.current.debouncedSearch).toBe('123')
  })

  test('should clear state to empty string when second returned fn is called', async () => {
    const {result} = renderHook(() => useSearch())
    act(() => result.current.onClearHandler())
    await act(async () => jest.runAllTimers())
    expect(result.current.search).toBe('')
  })

  test('should update state with event.target.value using default debounce', async () => {
    const {result} = renderHook(() => useSearch())
    act(() => result.current.onChangeHandler(event))
    expect(result.current.search).toBe('123')
    expect(result.current.debouncedSearch).toBe('')
    await act(async () => jest.advanceTimersByTime(100))
    expect(result.current.debouncedSearch).toBe('')
    await act(async () => jest.advanceTimersByTime(100))
    expect(result.current.debouncedSearch).toBe('')
    await act(async () => jest.advanceTimersByTime(300))
    expect(result.current.debouncedSearch).toBe('123')
  })
})
