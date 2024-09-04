/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import UseWindowWidth from '../useWindowWidth'

describe('useWindowWidth renders and accurately tracks viewport changes', () => {
  it('should accurately return initially rendered viewport', () => {
    global.innerWidth = 500

    const {result} = renderHook(() => UseWindowWidth())
    expect(result).toEqual({all: [0, 500], current: 500, error: undefined})
  })

  it('should accurately return viewport after resize', () => {
    global.innerWidth = 500

    const {result} = renderHook(() => UseWindowWidth())
    expect(result).toEqual({all: [0, 500], current: 500, error: undefined})

    global.innerWidth = 1000
    global.dispatchEvent(new Event('resize'))

    expect(result).toEqual({all: [0, 500, 1000], current: 1000, error: undefined})
  })
})
