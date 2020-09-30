/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import ColorPicker from '../ColorPicker'

describe('ColorPicker', () => {
  describe('getColorName', () => {
    it('returns name', () => {
      expect(ColorPicker.getColorName('#BD3C14')).toBe('Brick')
    })

    it('returns name without hash', () => {
      expect(ColorPicker.getColorName('BD3C14')).toBe('Brick')
    })

    it('returns undefined if color does not exists in PREDEFINED_COLORS', () => {
      expect(ColorPicker.getColorName('#111111')).toBeUndefined()
    })
  })
})
