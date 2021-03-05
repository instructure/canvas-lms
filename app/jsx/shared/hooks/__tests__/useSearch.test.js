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

describe('useSearch', () => {
  const event = {
    target: {
      value: '123'
    }
  }

  test('should create custom hook with initial state an empty string', () => {
    const {result} = renderHook(() => useSearch())
    expect(result.current[0]).toBe('')
  })

  test('should update state with event.target.value when first returned fn is called', () => {
    const {result} = renderHook(() => useSearch())
    act(() => result.current[1](event))
    expect(result.current[0]).toBe('123')
  })

  test('should clear state to empty string when second returned fn is called', () => {
    const {result} = renderHook(() => useSearch())
    act(() => result.current[2]())
    expect(result.current[0]).toBe('')
  })
})
