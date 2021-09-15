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
import useBoolean from '../useBoolean'

describe('useBoolean', () => {
  it('creates custom hook with state equal to initial value if initial value is boolean', () => {
    const {result} = renderHook(() => useBoolean(false))
    expect(result.current[0]).toBe(false)
  })

  it('creates custom hook with state equal to initial value coerced to boolean if initial value is not boolean', () => {
    const {result} = renderHook(() => useBoolean('abc'))
    expect(result.current[0]).toBe(true)
  })

  it('changes state to true when first exported fn is called', () => {
    const {result} = renderHook(() => useBoolean())
    act(() => {
      result.current[1]()
    })
    expect(result.current[0]).toBe(true)
  })

  it('changes state to false when second exported fn is called', () => {
    const {result} = renderHook(() => useBoolean())
    act(() => {
      result.current[2]()
    })
    expect(result.current[0]).toBe(false)
  })
})
