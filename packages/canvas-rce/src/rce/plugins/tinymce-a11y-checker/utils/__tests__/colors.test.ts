/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {stringifyRGBA, parseRGBA, restrictColorValues} from '../colors'

describe('stringifyRGBA', () => {
  it('converts colors to strings', () => {
    expect(stringifyRGBA({r: 1, g: 2, b: 3, a: 0.4})).toBe('rgba(1, 2, 3, 0.4)')
  })
})

describe('parseRGBA', () => {
  it('should parse a valid color', () => {
    expect(parseRGBA('rgba(1, 2, 3, 0.4)')).toEqual({r: 1, g: 2, b: 3, a: 0.4})
  })

  it('returns null for an invalid color string', () => {
    expect(parseRGBA('x')).toBeNull()
    expect(parseRGBA('rgba(1, 2')).toBeNull()
    expect(parseRGBA('rgba(1, 2, 3)')).toBeNull()
    expect(parseRGBA('rgba(1, 2, 3, 4, 5)')).toBeNull()
  })

  it('returns a 0 for a bad value in an otherwise valid color string', () => {
    expect(parseRGBA('rgba(1, a, 3, x)')).toEqual({r: 1, g: 0, b: 3, a: 0})
  })
})

describe('restrictColorValues', () => {
  it('restricts rgb values to max of 255', () => {
    expect(restrictColorValues({r: 300, g: 400, b: 500, a: 0.5})).toEqual({
      r: 255,
      g: 255,
      b: 255,
      a: 0.5,
    })
  })

  it('restricts a values to max of 1', () => {
    expect(restrictColorValues({r: 0, g: 0, b: 0, a: 1.5})).toEqual({
      r: 0,
      g: 0,
      b: 0,
      a: 1,
    })
  })

  it('raises rgba values to min of 0', () => {
    expect(restrictColorValues({r: -300, g: -400, b: -500, a: -8})).toEqual({
      r: 0,
      g: 0,
      b: 0,
      a: 0,
    })
  })
})
