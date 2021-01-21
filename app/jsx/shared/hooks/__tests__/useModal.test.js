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

import {renderHook, act} from '@testing-library/react-hooks'
import useModal from '../useModal'

describe('useModal', () => {
  test('should create custom hook with initial state false', () => {
    const {result} = renderHook(() => useModal())
    expect(result.current[0]).toBe(false)
  })

  test('should change state to true when first returned fn is called', () => {
    const {result} = renderHook(() => useModal())
    act(() => {
      result.current[1]()
    })
    expect(result.current[0]).toBe(true)
  })

  test('should change state to false when first then second returned fn is called', () => {
    const {result} = renderHook(() => useModal())
    act(() => {
      result.current[1]()
      result.current[2]()
    })
    expect(result.current[0]).toBe(false)
  })
})
