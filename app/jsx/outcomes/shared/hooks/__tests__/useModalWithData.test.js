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
import useModalWithData from '../useModalWithData'

describe('useModalWithData', () => {
  test('should create custom hook with initial state {open: false}', () => {
    const {result} = renderHook(() => useModalWithData())
    expect(result.current[0]).toEqual({open: false})
  })

  test('should add data to state and set {open: true} when first returned fn is called with data', () => {
    const {result} = renderHook(() => useModalWithData())
    const data = {id: '1'}
    act(() => {
      result.current[1](data)
    })
    expect(result.current[0]).toEqual({...data, open: true})
  })

  test('should set state to {open: true} when first returned fn is called with no data', () => {
    const {result} = renderHook(() => useModalWithData())
    act(() => {
      result.current[1]()
    })
    expect(result.current[0]).toEqual({open: true})
  })

  test('should remove data from state and set {open: false} when second returned fn is called', () => {
    const {result} = renderHook(() => useModalWithData())
    act(() => {
      result.current[1]()
      result.current[2]()
    })
    expect(result.current[0]).toEqual({open: false})
  })
})
