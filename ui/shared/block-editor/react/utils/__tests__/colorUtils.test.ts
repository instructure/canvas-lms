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

import {getContrastingColor, getContrastingButtonColor, white, black} from '../colorUtils'

// basically, just testing instui's `contrast` function
describe('colorUtils', () => {
  describe('getContrastingColor', () => {
    it('should return black when the color is white', () => {
      expect(getContrastingColor(white)).toBe(black)
    })

    it('should return white when the color is black', () => {
      expect(getContrastingColor(black)).toBe(white)
    })
  })

  describe('getContrastingButtonColor', () => {
    it('should return primary-inverse when the color is white', () => {
      expect(getContrastingButtonColor(white)).toBe('primary-inverse')
    })

    it('should return secondary when the color is black', () => {
      expect(getContrastingButtonColor(black)).toBe('secondary')
    })
  })
})
