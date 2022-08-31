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
import hex2rgb from '../hex2rgb'

describe('hex2rgb', () => {
  it('converts hex code to rgb object', () => {
    expect(hex2rgb('#000000')).toEqual({r: 0, g: 0, b: 0})
    expect(hex2rgb('#FFFFFF')).toEqual({r: 255, g: 255, b: 255})
  })

  it('converts hex codes case-insensitively', () => {
    expect(hex2rgb('#FFFFFF')).toEqual({r: 255, g: 255, b: 255})
    expect(hex2rgb('#FfFfFf')).toEqual({r: 255, g: 255, b: 255})
    expect(hex2rgb('#ffffff')).toEqual({r: 255, g: 255, b: 255})
  })

  it('works if a leading # is not present', () => {
    expect(hex2rgb('000000')).toEqual({r: 0, g: 0, b: 0})
  })

  describe('invalid input', () => {
    it('does not handle shorthand hex codes', () => {
      expect(hex2rgb('#000')).toEqual(null)
    })

    it('handles invalid hex codes', () => {
      expect(hex2rgb('#00000')).toEqual(null)
      expect(hex2rgb('#GFFFFF')).toEqual(null)
    })
  })
})
