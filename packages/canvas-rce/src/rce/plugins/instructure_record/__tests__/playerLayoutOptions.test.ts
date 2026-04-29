/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {
  CUSTOM,
  LARGE,
  labelForPlayerLayoutSize,
  MEDIUM,
  SMALL,
  scalePlayerLayoutForHeight,
  scalePlayerLayoutForWidth,
  EXTRA_LARGE,
} from '../playerLayoutOptions'

describe('playerLayoutOptions', () => {
  describe('scalePlayerLayoutForWidth', () => {
    it('returns null dimensions for null input', () => {
      expect(scalePlayerLayoutForWidth(0, 0, null)).toEqual({width: null, height: null})
    })

    it('derives height from width when width <= 720', () => {
      // 400 * (9/16) + 48 = 225 + 48 = 273
      expect(scalePlayerLayoutForWidth(0, 0, 400)).toEqual({width: 400, height: 273})
    })

    it('subtracts sidebar before ratio when width > 720', () => {
      // (1032 - 300) * (9/16) + 48 = 732 * 0.5625 + 48 = 411.75 + 48 ≈ 460
      expect(scalePlayerLayoutForWidth(0, 0, 1032)).toEqual({width: 1032, height: 460})
    })
  })

  describe('scalePlayerLayoutForHeight', () => {
    it('returns null dimensions for null input', () => {
      expect(scalePlayerLayoutForHeight(0, 0, null)).toEqual({width: null, height: null})
    })

    it('derives width from height when result <= 720', () => {
      // (273 - 48) * (16/9) = 225 * 1.777... = 400
      expect(scalePlayerLayoutForHeight(0, 0, 273)).toEqual({width: 400, height: 273})
    })

    it('adds sidebar when derived video width > 720', () => {
      // (460 - 48) * (16/9) = 412 * 1.777... = 732.4 > 720 → 732 + 300 = 1032
      expect(scalePlayerLayoutForHeight(0, 0, 460)).toEqual({width: 1032, height: 460})
    })
  })

  describe('labelForPlayerLayoutSize', () => {
    it.each([
      [SMALL, '400', '273'],
      [MEDIUM, '480', '318'],
      [LARGE, '700', '442'],
      [EXTRA_LARGE, '850', '357'],
    ])('returns a label containing %s dimensions', (size, width, height) => {
      const label = labelForPlayerLayoutSize(size)
      expect(label).toContain(width)
      expect(label).toContain(height)
    })

    it('returns "Custom" for CUSTOM', () => {
      expect(labelForPlayerLayoutSize(CUSTOM)).toEqual('Custom')
    })

    it('returns "Custom" for unknown sizes', () => {
      expect(labelForPlayerLayoutSize('unknown')).toEqual('Custom')
    })
  })
})
