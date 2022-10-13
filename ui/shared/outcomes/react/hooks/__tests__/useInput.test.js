/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import useInput from '../useInput'

describe('useInput', () => {
  const event = {
    target: {
      value: '1',
    },
  }

  test('should create custom hook with initial state', () => {
    const {result} = renderHook(() => useInput('1'))
    expect(result.current[0]).toBe('1')
  })

  test('should create custom hook with initial state equal to empty string if no initial value provided', () => {
    const {result} = renderHook(() => useInput())
    expect(result.current[0]).toBe('')
  })

  test('should create custom hook with initial state equal to empty string if initial value is null', () => {
    const {result} = renderHook(() => useInput(null))
    expect(result.current[0]).toBe('')
  })

  test('should set state to value when event.target.value is provided to changeValue fn', () => {
    const {result} = renderHook(() => useInput())
    act(() => result.current[1](event))
    expect(result.current[0]).toBe('1')
  })

  test('should set valueChanged to true if value is different than initial value', () => {
    const {result} = renderHook(() => useInput())
    act(() => result.current[1](event))
    expect(result.current[2]).toBe(true)
  })

  test('should set valueChanged to false if value is the same as initial value', () => {
    const {result} = renderHook(() => useInput('1'))
    act(() => result.current[1](event))
    expect(result.current[2]).toBe(false)
  })

  test('should set state to value when value is provided to changeValue fn', () => {
    const {result} = renderHook(() => useInput())
    act(() => result.current[1]('2'))
    expect(result.current[0]).toBe('2')
  })
})
