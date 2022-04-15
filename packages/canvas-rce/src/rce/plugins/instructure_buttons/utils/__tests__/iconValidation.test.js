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

import {
  hasBackgroundColor,
  hasVisibleText,
  hasImage,
  hasVisibleOutline,
  validIcon
} from '../iconValidation'

describe('icon validation', () => {
  let settings

  beforeEach(() => {
    settings = {
      color: null,
      encodedImage: '',
      outlineColor: null,
      outlineSize: 'none',
      text: '',
      textColor: null
    }
  })

  describe('hasBackgroundColor', () => {
    it('is false if the icon has no background color', () => {
      expect(hasBackgroundColor(settings)).toBe(false)
    })

    it('is true if the icon has a background color', () => {
      settings.color = '#000000'
      expect(hasBackgroundColor(settings)).toBe(true)
    })
  })

  describe('hasVisibleText', () => {
    it('is false if the icon has no text color', () => {
      expect(hasVisibleText(settings)).toBe(false)
    })

    it('is false if the icon has text color but no text', () => {
      settings.textColor = '#000000'
      expect(hasVisibleText(settings)).toBe(false)
    })

    it('is true if the icon has text color and text', () => {
      settings.textColor = '#000000'
      settings.text = 'blah'
      expect(hasVisibleText(settings)).toBe(true)
    })
  })

  describe('hasImage', () => {
    it('is false if the icon has no image', () => {
      expect(hasImage(settings)).toBe(false)
    })

    it('is true if the icon has an image', () => {
      settings.encodedImage = 'data:image/svg+xml;base64,PHN2ZyB3aWR...'
      expect(hasImage(settings)).toBe(true)
    })
  })

  describe('hasVisibleOutline', () => {
    it('is false if the icon has no outline color', () => {
      expect(hasVisibleOutline(settings)).toBe(false)
    })

    it('is false if the icon has an outline color but outline size is none', () => {
      settings.outlineColor = '#000000'
      expect(hasVisibleOutline(settings)).toBe(false)
    })

    it('is true if the icon has outline color and outline size', () => {
      settings.outlineColor = '#000000'
      settings.outlineSize = 'small'
      expect(hasVisibleOutline(settings)).toBe(true)
    })
  })

  describe('validIcon', () => {
    it('is false if none of the criteria are met', () => {
      expect(validIcon(settings)).toBe(false)
    })

    it('is true if the icon has a background color', () => {
      settings.color = '#000000'
      expect(validIcon(settings)).toBe(true)
    })

    it('is true if the icon has text color and text', () => {
      settings.textColor = '#000000'
      settings.text = 'blah'
      expect(validIcon(settings)).toBe(true)
    })

    it('is true if the icon has an image', () => {
      settings.encodedImage = 'data:image/svg+xml;base64,PHN2ZyB3aWR...'
      expect(validIcon(settings)).toBe(true)
    })

    it('is true if the icon has outline color and outline size', () => {
      settings.outlineColor = '#000000'
      settings.outlineSize = 'small'
      expect(validIcon(settings)).toBe(true)
    })
  })
})
