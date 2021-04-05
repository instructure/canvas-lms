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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks/dom'
import useStateWithCallback from '../index'

const initialValue = 'initial value'

describe('useStateWithCallback', () => {
  const savedUseState = React.useState
  let stateSetter
  let callback

  beforeEach(() => {
    callback = jest.fn()
    stateSetter = jest.fn()
    React.useState = jest.fn(init => [init, stateSetter])
  })

  afterEach(() => {
    React.useState = savedUseState
  })

  it('calls useState with the same initial value and returns it to us', () => {
    const {result} = renderHook(() => useStateWithCallback(initialValue))
    expect(React.useState).toHaveBeenCalledWith(initialValue)
    expect(result.current[0]).toBe(initialValue)
  })

  it('calls useState’s setter when the state is set, like normal', () => {
    const newValue = 'new value'
    const {result, rerender} = renderHook(() => useStateWithCallback(initialValue))
    const setState = result.current[1]
    setState(newValue)
    rerender()
    expect(stateSetter).toHaveBeenCalledWith(newValue)
  })

  it('calls the callback if given after setting state with the new value', () => {
    const newValue = 'new value'
    const {result, rerender} = renderHook(() => useStateWithCallback(initialValue))
    const setState = result.current[1]
    setState(newValue, callback)
    rerender()
    expect(callback).toHaveBeenCalledWith(newValue)
  })

  it('does not call the callback before the component rerenders', () => {
    const newValue = 'new value'
    const {result} = renderHook(() => useStateWithCallback(initialValue))
    const setState = result.current[1]
    setState(newValue, callback)
    expect(callback).not.toHaveBeenCalled()
  })

  it('does not call the callback if the state is set to the same value', () => {
    const obj1 = {moe: 1, larry: 2, curly: 3}
    const obj2 = {moe: 1, larry: 2, curly: 3}
    const {result, rerender} = renderHook(() => useStateWithCallback(obj1))
    const setState = result.current[1]
    setState(obj2, callback)
    rerender()
    expect(callback).not.toHaveBeenCalled()
  })

  it('calls the callback correctly if a function is given to the setter', () => {
    const newValue = str => str.replace(/initial/, 'new')
    const {result, rerender} = renderHook(() => useStateWithCallback(initialValue))
    const setState = result.current[1]
    setState(newValue, callback)
    rerender()
    expect(callback).toHaveBeenCalledWith('new value')
    expect(stateSetter).toHaveBeenCalledWith(newValue)
  })

  describe('by default, with only one callback at the end', () => {
    it('calls the callback correctly on multiple calls to the setter', () => {
      const {result, rerender} = renderHook(() => useStateWithCallback(initialValue))
      const setState = result.current[1]
      setState('value 2', callback)
      setState('value 3', callback)
      rerender()
      expect(callback).toHaveBeenCalledTimes(1)
      expect(callback).toHaveBeenLastCalledWith('value 3')
    })

    it('calls the callback correctly on multiple calls with functions', () => {
      const {result, rerender} = renderHook(() => useStateWithCallback(10))
      const setState = result.current[1]
      setState(x => x * 2, callback) // 10 * 2 => 20
      setState(x => x + 1, callback) // 20 + 1 => 21
      rerender()
      expect(callback).toHaveBeenCalledTimes(1)
      expect(callback).toHaveBeenLastCalledWith(21)
    })
  })

  describe('when multiple intermediate callbacks are requested', () => {
    it('calls the callback correctly on multiple calls to the setter', () => {
      const {result, rerender} = renderHook(() => useStateWithCallback(initialValue, true))
      const setState = result.current[1]
      setState('value 2', callback)
      setState('value 3', callback)
      rerender()
      expect(callback).toHaveBeenCalledTimes(2)
      expect(callback).toHaveBeenNthCalledWith(1, 'value 2')
      expect(callback).toHaveBeenNthCalledWith(2, 'value 3')
    })

    it('calls the callback correctly on multiple calls with functions', () => {
      const {result, rerender} = renderHook(() => useStateWithCallback(10, true))
      const setState = result.current[1]
      setState(x => x * 2, callback) // 10 * 2 => 20
      setState(x => x + 1, callback) // 20 + 1 => 21
      rerender()
      expect(callback).toHaveBeenCalledTimes(2)
      expect(callback).toHaveBeenNthCalledWith(1, 20)
      expect(callback).toHaveBeenNthCalledWith(2, 21)
    })

    it('calls an intermediate callback only if the value changes', () => {
      const {result, rerender} = renderHook(() => useStateWithCallback(10, true))
      const setState = result.current[1]
      setState(x => x * 2, callback) // 10 * 2 => 20
      setState(x => Math.round(x)) // round(20) => 20, no change
      setState(x => x + 1, callback) // 20 + 1 => 21
      rerender()
      expect(callback).toHaveBeenCalledTimes(2)
      expect(callback).toHaveBeenNthCalledWith(1, 20)
      expect(callback).toHaveBeenNthCalledWith(2, 21)
    })
  })

  it('throws an error when the callback isn’t a function', () => {
    const {result} = renderHook(() => useStateWithCallback(initialValue))
    const setState = result.current[1]
    expect(() => {
      setState(5, 'I am not a function')
    }).toThrow(TypeError)
  })
})
