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

import {isCaretAtBoldText, isCaretAtStyledText, isElementBold, isElementOfStyle} from '../dom'
import {setCaretToOffset} from '../kb'

describe('dom utilities', () => {
  describe('isElementBold', () => {
    it('should return true if the element is bold', () => {
      const div = document.createElement('div')
      div.innerHTML = '<b>bold</b>'
      const b = div.querySelector('b') as HTMLElement
      expect(isElementBold(b)).toBe(true)
    })

    it('should return true if the element is bold with font-weight', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p style="font-weight: bold">bold</p>'
      const p = div.querySelector('p') as HTMLElement
      expect(isElementBold(p)).toBe(true)
    })

    it('should return true if the element is bold with font-weight number', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p style="font-weight: 700">bold</p>'
      const p = div.querySelector('p') as HTMLElement
      expect(isElementBold(p)).toBe(true)
    })

    it('should return false if the element is not bold', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p>not bold</p>'
      const p = div.querySelector('p') as HTMLElement
      expect(isElementBold(p)).toBe(false)
    })
  })

  describe('isCaretAtBoldText', () => {
    it('should return true if the caret is at bold text', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p>this is <b>bold</b> text'
      document.body.appendChild(div)
      const b = div.querySelector('b') as HTMLElement
      setCaretToOffset(b, 2)
      expect(isCaretAtBoldText()).toBe(true)
    })

    it('should return false if the caret is not at bold text', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p>this is <b>bold</b> text'
      document.body.appendChild(div)
      const p = div.querySelector('p') as HTMLElement
      setCaretToOffset(p, 2)
      expect(isCaretAtBoldText()).toBe(false)
    })
  })

  describe('isElementOfStyle', () => {
    // fails in jsdom 25
    it.skip('should return true if the element has the style', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p style="color: red">red</p>'
      const p = div.querySelector('p') as HTMLElement
      expect(isElementOfStyle('color', 'red', p)).toBe(true)
    })

    it('should return false if the element does not have the style', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p>not red</p>'
      const p = div.querySelector('p') as HTMLElement
      expect(isElementOfStyle('color', 'red', p)).toBe(false)
    })
  })

  describe('isCaretAtStyledText', () => {
    // fails in jsdom 25
    it.skip('should return true if the caret is at text with the style', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p style="color: red">red</p>'
      document.body.appendChild(div)
      const p = div.querySelector('p') as HTMLElement
      setCaretToOffset(p, 2)
      expect(isCaretAtStyledText('color', 'red')).toBe(true)
    })

    it('should return false if the caret is not at text with the style', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p style="color: red">red</p>'
      document.body.appendChild(div)
      const p = div.querySelector('p') as HTMLElement
      setCaretToOffset(p, 2)
      expect(isCaretAtStyledText('color', 'blue')).toBe(false)
    })
  })
})
