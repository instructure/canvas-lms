/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks/dom'
import useInputFocus from '../useInputFocus'

describe('useInputFocus', () => {
  const inputFields = ['abc', 'def']

  it('should create custom hook with map of input field refs', () => {
    const {result} = renderHook(() => useInputFocus(inputFields))

    expect(result.current.inputElRefs.size).toEqual(2)
    expect(result.current.inputElRefs.get('abc').current).toEqual(null)
    expect(result.current.inputElRefs.get('def').current).toEqual(null)
  })

  it('should set value of individual input field ref', () => {
    const {result} = renderHook(() => useInputFocus(inputFields))
    result.current.setInputElRef('123', 'abc')

    expect(result.current.inputElRefs.get('abc').current).toEqual('123')
  })
})
