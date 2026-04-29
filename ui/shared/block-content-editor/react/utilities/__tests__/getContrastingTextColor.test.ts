/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {getContrastingTextColor, getContrastingTextColorCached} from '../getContrastingTextColor'

describe('getContrastingTextColor', () => {
  const expectValidContrastingColor = (result: string | null) => {
    expect(result).not.toBeNull()
    expect(result).toMatch(/^#[0-9A-Fa-f]{6}$/)
  }

  describe('invalid color inputs', () => {
    it('returns null for empty string', () => {
      expect(getContrastingTextColor('')).toBeNull()
    })

    it('returns null for null input', () => {
      expect(getContrastingTextColor(null as any)).toBeNull()
    })

    it('returns null for undefined input', () => {
      expect(getContrastingTextColor(undefined as any)).toBeNull()
    })

    it('returns null for whitespace-only string', () => {
      expect(getContrastingTextColor('   ')).toBeNull()
    })

    it('returns null for just hash symbol', () => {
      expect(getContrastingTextColor('#')).toBeNull()
    })

    it('returns null for invalid color format', () => {
      expect(getContrastingTextColor('invalid-color')).toBeNull()
    })

    it('returns null for incomplete hex color', () => {
      expect(getContrastingTextColor('#FF')).toBeNull()
    })
  })

  describe('valid color inputs', () => {
    it('accepts 3-digit hex colors (#RGB)', () => {
      const result = getContrastingTextColor('#FFF')
      expectValidContrastingColor(result)
    })

    it('accepts 4-digit hex colors (#RGBA)', () => {
      const result = getContrastingTextColor('#FFFF')
      expectValidContrastingColor(result)
    })

    it('accepts 6-digit hex colors (#RRGGBB)', () => {
      const result = getContrastingTextColor('#FFFFFF')
      expectValidContrastingColor(result)
    })

    it('accepts 8-digit hex colors (#RRGGBBAA)', () => {
      const result = getContrastingTextColor('#FFFFFFFF')
      expectValidContrastingColor(result)
    })

    it('accepts lowercase hex colors', () => {
      const result = getContrastingTextColor('#ffffff')
      expectValidContrastingColor(result)
    })

    it('accepts mixed case hex colors', () => {
      const result = getContrastingTextColor('#FfFfFf')
      expectValidContrastingColor(result)
    })
  })
})

describe('getContrastingTextColorCached', () => {
  it('returns the same result as non-cached version', () => {
    const color = '#FFFFFF'
    const cachedResult = getContrastingTextColorCached(color)
    const nonCachedResult = getContrastingTextColor(color)
    expect(cachedResult).toBe(nonCachedResult)
  })

  it('returns cached result on subsequent calls', () => {
    const color = '#000000'
    const firstCall = getContrastingTextColorCached(color)
    const secondCall = getContrastingTextColorCached(color)
    expect(firstCall).toBe(secondCall)
  })
})
