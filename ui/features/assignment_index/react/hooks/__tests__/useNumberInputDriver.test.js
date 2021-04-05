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

import {act, renderHook} from '@testing-library/react-hooks/dom'
import useNumberInputDriver from '../useNumberInputDriver'

describe('useNumberInputDriver', () => {
  it('handles null as an initial input', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: null}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('')
  })

  it('handles a number as the initial value', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    expect(result.current[0].numberValue).toBe(42)
    expect(result.current[0].inputValue).toBe('42')
  })

  it('changes the values when a number is typed in', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onChange({target: {value: '23'}}))
    expect(result.current[0].numberValue).toBe(23)
    expect(result.current[0].inputValue).toBe('23')
  })

  it('changes the values when changed to an empty string', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onChange({target: {value: ''}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('')
  })

  it('does not allow a change when a non-numeric string is input', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onChange({target: {value: 'abc'}}))
    expect(result.current[0].numberValue).toBe(42)
    expect(result.current[0].inputValue).toBe('42')
  })

  it('allows increment from existing value', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onIncrement())
    expect(result.current[0].numberValue).toBe(43)
    expect(result.current[0].inputValue).toBe('43')
  })

  it('will not increment past max value', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: 42, maxNumberValue: 42})
    )
    act(() => result.current[1].onIncrement())
    expect(result.current[0].numberValue).toBe(42)
    expect(result.current[0].inputValue).toBe('42')
  })

  it('allows increment from null', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: null}))
    act(() => result.current[1].onIncrement())
    expect(result.current[0].numberValue).toBe(1)
    expect(result.current[0].inputValue).toBe('1')
  })

  it('increment from null uses minValue if it is > 1', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: 42})
    )
    act(() => result.current[1].onIncrement())
    expect(result.current[0].numberValue).toBe(42)
    expect(result.current[0].inputValue).toBe('42')
  })

  it('allows decrement from existing value', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onDecrement())
    expect(result.current[0].numberValue).toBe(41)
    expect(result.current[0].inputValue).toBe('41')
  })

  it('allows decrement from null', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: null}))
    act(() => result.current[1].onDecrement())
    expect(result.current[0].numberValue).toBe(1)
    expect(result.current[0].inputValue).toBe('1')
  })

  it('decrement from null uses maxValue if it is < 0', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: -10, maxNumberValue: -1})
    )
    act(() => result.current[1].onDecrement())
    expect(result.current[0].numberValue).toBe(-1)
    expect(result.current[0].inputValue).toBe('-1')
  })

  it('will not decrement below min value', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 1}))
    act(() => result.current[1].onDecrement())
    expect(result.current[0].numberValue).toBe(1)
    expect(result.current[0].inputValue).toBe('1')
  })

  it('allows numbers to be typed below a positive minimum value, but does not set numberValue', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: 42})
    )
    act(() => result.current[1].onChange({target: {value: '5'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('5')
  })

  it('allows negative numbers to be typed above a negative maximum value, but does not set numberValue', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: -42, maxNumberValue: -30})
    )
    act(() => result.current[1].onChange({target: {value: '-5'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('-5')
  })

  it('does not allow a positive number to be typed when the maximum value is negative', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: -42, maxNumberValue: -30})
    )
    act(() => result.current[1].onChange({target: {value: '5'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('')
  })

  it('does not allow positive numbers to be typed above the positive maximum value', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: 5, maxNumberValue: 42})
    )
    act(() => result.current[1].onChange({target: {value: '50'}}))
    expect(result.current[0].numberValue).toBe(5)
    expect(result.current[0].inputValue).toBe('5')
  })

  it('does not allow negative numbers to be typed below the negative minimum value', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: -5, minNumberValue: -42})
    )
    act(() => result.current[1].onChange({target: {value: '-50'}}))
    expect(result.current[0].numberValue).toBe(-5)
    expect(result.current[0].inputValue).toBe('-5')
  })

  it('disallows minus if minNumberValue is >= 0', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: 0})
    )
    act(() => result.current[1].onChange({target: {value: '-'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('')
  })

  it('allows minus if minNumberValue is null', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: null})
    )
    act(() => result.current[1].onChange({target: {value: '-'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('-')
  })

  it('allows minus if minNumberValue is < 0', () => {
    const {result} = renderHook(() =>
      useNumberInputDriver({initialNumberValue: null, minNumberValue: -10})
    )
    act(() => result.current[1].onChange({target: {value: '-'}}))
    expect(result.current[0].numberValue).toBeNull()
    expect(result.current[0].inputValue).toBe('-')
  })

  it('ignores non-numbers characters after numeric characters', () => {
    const {result} = renderHook(() => useNumberInputDriver({initialNumberValue: 42}))
    act(() => result.current[1].onChange({target: {value: '42a'}}))
    expect(result.current[0].numberValue).toBe(42)
    expect(result.current[0].inputValue).toBe('42')
  })
})
