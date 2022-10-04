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

import {shouldIgnoreClose, ICON_MAKER_ADD_IMAGE_MENU_ID} from '../IconMakerClose'

describe('IconMakerClose', () => {
  const createElementTree = (attribute: string, value: string) => {
    const child = document.createElement('button')
    const parent = document.createElement('div')
    const grandParent = document.createElement('span')
    grandParent.setAttribute(attribute, value)
    grandParent.appendChild(parent)
    parent.appendChild(child)
    return child
  }

  describe('Image Menu Click', () => {
    it('returns true if element has correct data-position-content', () => {
      const el = document.createElement('div')
      el.setAttribute('data-position-content', ICON_MAKER_ADD_IMAGE_MENU_ID)
      expect(shouldIgnoreClose(el)).toBe(true)
    })

    it('returns false if element does not have correct data-position-content', () => {
      const el = document.createElement('div')
      el.setAttribute('data-position-content', 'other data')
      expect(shouldIgnoreClose(el)).toBe(false)
    })

    it('returns true if parent element has correct data-position-content', () => {
      const el = createElementTree('data-position-content', ICON_MAKER_ADD_IMAGE_MENU_ID)
      expect(shouldIgnoreClose(el)).toBe(true)
    })

    it('returns false if parent element does not have correct data-position-content', () => {
      const el = createElementTree('data-position-content', 'other data')
      expect(shouldIgnoreClose(el)).toBe(false)
    })
  })

  describe('RCE Click', () => {
    it('returns true if element has correct data-id', () => {
      const el = document.createElement('div')
      el.setAttribute('data-id', 'tinymce')
      expect(shouldIgnoreClose(el, 'tinymce')).toBe(true)
    })

    it('returns false if element does not have correct data-id', () => {
      const el = document.createElement('div')
      el.setAttribute('id', 'otherid')
      expect(shouldIgnoreClose(el, 'tinymce')).toBe(false)
    })

    it('returns true if parent element has correct data-id', () => {
      const el = createElementTree('data-id', 'tinymce')
      expect(shouldIgnoreClose(el, 'tinymce')).toBe(true)
    })

    it('returns false if parent element does not have correct data-id', () => {
      const el = createElementTree('data-id', 'otherid')
      expect(shouldIgnoreClose(el, 'tinymce')).toBe(false)
    })
  })
})
