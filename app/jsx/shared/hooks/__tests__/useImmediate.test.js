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

import {renderHook} from '@testing-library/react-hooks'
import useImmediate from '../useImmediate'

describe('useImmediate', () => {
  it('runs the function the first time', () => {
    const fn = jest.fn()
    renderHook(() => useImmediate(fn))
    expect(fn).toHaveBeenCalledTimes(1)
  })

  it('runs the cleanup function on rerender and unmount', () => {
    const cleanup = jest.fn()
    const fn = jest.fn(() => cleanup)
    const {rerender, unmount} = renderHook(() => useImmediate(fn))
    rerender()
    expect(fn).toHaveBeenCalledTimes(2)
    expect(cleanup).toHaveBeenCalledTimes(1)
    unmount()
    expect(fn).toHaveBeenCalledTimes(2)
    expect(cleanup).toHaveBeenCalledTimes(2)
  })

  it('runs fn initially when deps are specified', () => {
    const fn = jest.fn()
    renderHook(() => useImmediate(fn, ['dep']))
    expect(fn).toHaveBeenCalledTimes(1)
  })

  it('does not rerun the fn or the cleanup when deps have not changed', () => {
    const cleanup = jest.fn()
    const fn = jest.fn(() => cleanup)
    const {rerender} = renderHook(() => useImmediate(fn, ['dep']))
    rerender()
    expect(fn).toHaveBeenCalledTimes(1)
    expect(cleanup).toHaveBeenCalledTimes(0)
  })

  it('reruns fn and cleanup when deps change', () => {
    let dep = 'foo'
    const cleanup = jest.fn()
    const fn = jest.fn(() => cleanup)
    const {rerender} = renderHook(() => useImmediate(fn, [dep]))
    dep = 'bar'
    rerender()
    expect(fn).toHaveBeenCalledTimes(2)
    expect(cleanup).toHaveBeenCalledTimes(1)
  })

  it('only does a shallow comparison by default', () => {
    let dep = {foo: 'bar'}
    const cleanup = jest.fn()
    const fn = jest.fn(() => cleanup)
    const {rerender} = renderHook(() => useImmediate(fn, [dep]))
    dep = {foo: 'bar'}
    rerender()
    expect(fn).toHaveBeenCalledTimes(2)
    expect(cleanup).toHaveBeenCalledTimes(1)
  })

  it('does a deep comparison if specified', () => {
    let dep = {foo: 'bar'}
    const cleanup = jest.fn()
    const fn = jest.fn(() => cleanup)
    const {rerender} = renderHook(() => useImmediate(fn, [dep], {deep: true}))
    dep = {foo: 'bar'}
    rerender()
    expect(fn).toHaveBeenCalledTimes(1)
    expect(cleanup).toHaveBeenCalledTimes(0)
    dep = {foo: 'xyz'}
    rerender()
    expect(fn).toHaveBeenCalledTimes(2)
    expect(cleanup).toHaveBeenCalledTimes(1)
  })
})
