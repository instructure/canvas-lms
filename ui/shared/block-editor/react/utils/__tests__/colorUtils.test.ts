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

import {
  getContrastingColor,
  getContrastingButtonColor,
  getColorsInUse,
  getEffectiveBackgroundColor,
  getEffectiveColor,
  white,
  black,
} from '../colorUtils'

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

  describe('getColorsInUse', () => {
    it('returns the colors in use', () => {
      const query = {
        getSerializedNodes: () => ({
          1: {props: {color: '#000000', background: '#FFFFFF'}},
          2: {props: {color: '#abcdef', background: '#12345600'}},
          3: {props: {color: '#abcdef'}},
          4: {props: {}},
          5: {props: {background: '#ababab'}},
          6: {props: {color: 'var(--ic-brand-font-color-dark)', background: 'transparent'}},
          7: {props: {color: '#ff0000'}},
        }),
      }

      const colors = getColorsInUse(query)
      expect(colors).toEqual({
        foreground: ['#ff0000', '#abcdef'],
        background: ['#ababab'],
        border: [],
      })
    })
  })

  describe('getEffectiveBackgroundColor', () => {
    it('returns white if given no element', () => {
      expect(getEffectiveBackgroundColor(null)).toBe('#ffffff')
    })

    it('returns the elements background color', () => {
      const elem = document.createElement('div')
      elem.style.backgroundColor = 'rgb(255, 0, 0)'
      expect(getEffectiveBackgroundColor(elem)).toBe('#ff0000')
    })

    it('returns the first ancestor with a non-transparent background color', () => {
      const elem = document.createElement('div')
      const parent = document.createElement('div')
      parent.style.backgroundColor = 'transparent'
      parent.appendChild(elem)
      const grandparent = document.createElement('div')
      grandparent.style.backgroundColor = 'rgb(255, 0, 0)'
      grandparent.appendChild(parent)
      expect(getEffectiveBackgroundColor(elem)).toBe('#ff0000')
    })
  })

  describe('getEffectiveColor', () => {
    it('returns black if given no element', () => {
      // @ts-expect-error
      expect(getEffectiveColor(null)).toBe('#000000')
    })

    it('returns the elements color', () => {
      const elem = document.createElement('div')
      elem.style.color = 'rgb(255, 0, 0)'
      expect(getEffectiveColor(elem)).toBe('#ff0000')
    })
  })
})
