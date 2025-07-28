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

import {type KeyboardEvent} from 'react'
import {
  isAnyModifierKeyPressed,
  getCaretPosition,
  isCaretAtEnd,
  setCaretToEnd,
  setCaretToOffset,
  shouldAddNewNode,
  removeTrailingEmptyParagraphTags,
  shouldDeleteNode,
  getArrowNext,
  getArrowPrev,
} from '../kb'

const makeKeyboardEvent = (opts = {}) => {
  return {
    ctrlKey: false,
    metaKey: false,
    shiftKey: false,
    altKey: false,
    ...opts,
  } as KeyboardEvent
}

describe('keyboard utilities', () => {
  describe('isAnyModifierKeyPressed', () => {
    it('should return false if no modifier key is pressed', () => {
      expect(isAnyModifierKeyPressed(makeKeyboardEvent())).toBe(false)
    })

    it('should return true if any modifier key is pressed', () => {
      expect(isAnyModifierKeyPressed(makeKeyboardEvent({ctrlKey: true}))).toBe(true)
      expect(isAnyModifierKeyPressed(makeKeyboardEvent({metaKey: true}))).toBe(true)
      expect(isAnyModifierKeyPressed(makeKeyboardEvent({shiftKey: true}))).toBe(true)
      expect(isAnyModifierKeyPressed(makeKeyboardEvent({altKey: true}))).toBe(true)
    })
  })

  describe('getCaretPosition', () => {
    it('should return the 0 if there is no selection', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const pos = getCaretPosition(div)
      expect(pos).toBe(0)
    })

    it('should return the caret position if there is a selection', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const textNode = div.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 5)
      range.setEnd(textNode, 5)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      const pos = getCaretPosition(div)
      expect(pos).toBe(5)
    })
  })

  describe('isCaretAtEnd', () => {
    it('returns true if the caret is at the end of the text', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const textNode = div.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 11)
      range.setEnd(textNode, 11)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      expect(isCaretAtEnd(div)).toBe(true)
    })

    it('returns false if the caret is not at the end of the text', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const textNode = div.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 5)
      range.setEnd(textNode, 5)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      expect(isCaretAtEnd(div)).toBe(false)
    })
  })

  describe('setCaretToEnd', () => {
    it('should set the caret to the end of the text', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const textNode = div.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 0)
      range.setEnd(textNode, 0)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      expect(isCaretAtEnd(div)).toBe(false)

      setCaretToEnd(div)
      expect(isCaretAtEnd(div)).toBe(true)
    })
  })

  describe('setCaretToOffset', () => {
    it('should set the caret to the offset', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p>hello world</p>'
      document.body.appendChild(div)
      const p = div.querySelector('p') as HTMLElement
      const textNode = p.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 0)
      range.setEnd(textNode, 0)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      expect(getCaretPosition(div)).toBe(0)

      setCaretToOffset(p, 5)
      expect(getCaretPosition(div)).toBe(5)
    })
  })

  describe('shouldAddNewNode', () => {
    it('should return true if this is the 2nd Enter key press', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      setCaretToEnd(div)
      expect(shouldAddNewNode(makeKeyboardEvent({key: 'Enter', currentTarget: div}), 'Enter')).toBe(
        true,
      )
    })

    it('should return false if there is no text content', () => {
      const div = document.createElement('div')
      document.body.appendChild(div)
      setCaretToEnd(div)
      expect(shouldAddNewNode(makeKeyboardEvent({key: 'Enter', currentTarget: div}), 'Enter')).toBe(
        false,
      )
    })

    it('should return false if a modifier key is pressed', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      setCaretToEnd(div)
      expect(
        shouldAddNewNode(
          makeKeyboardEvent({key: 'Enter', currentTarget: div, ctrlKey: true}),
          'Enter',
        ),
      ).toBe(false)
    })

    it('should return false if the caret is not at the end of the text', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      const textNode = div.firstChild as Text
      const range = document.createRange()
      range.setStart(textNode, 5)
      range.setEnd(textNode, 5)
      const sel = window.getSelection()
      sel?.removeAllRanges()
      sel?.addRange(range)
      expect(shouldAddNewNode(makeKeyboardEvent({key: 'Enter', currentTarget: div}), 'Enter')).toBe(
        false,
      )
    })

    it('should return false if this is not the 2nd Enter key press', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      setCaretToEnd(div)
      expect(shouldAddNewNode(makeKeyboardEvent({key: 'Enter', currentTarget: div}), 'a')).toBe(
        false,
      )
    })
  })

  describe('removeTrailingEmptyParagraphTags', () => {
    it('should remove the last paragraph tag if it is empty', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p id="p1">hello</p><p id="p2"></p>'
      document.body.appendChild(div)
      removeTrailingEmptyParagraphTags(div)
      expect(div.innerHTML).toBe('<p id="p1">hello</p>')
    })

    it('should not remove the last paragraph tag if it has content', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p id="p1">hello</p><p id="p2">world</p>'
      document.body.appendChild(div)
      removeTrailingEmptyParagraphTags(div)
      expect(div.innerHTML).toBe('<p id="p1">hello</p><p id="p2">world</p>')
    })

    it('should do nothing if there are no paragraph tags', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      removeTrailingEmptyParagraphTags(div)
      expect(div.innerHTML).toBe('hello world')
    })

    it('should do nothing if the last element is not a paragraph tag', () => {
      const div = document.createElement('div')
      div.innerHTML = '<p id="p1">hello</p><div id="p2"></div>'
      document.body.appendChild(div)
      removeTrailingEmptyParagraphTags(div)
      expect(div.innerHTML).toBe('<p id="p1">hello</p><div id="p2"></div>')
    })
  })

  describe('shouldDeleteNode', () => {
    it('should return true if the delete key is pressed in an empty element', () => {
      const div = document.createElement('div')
      document.body.appendChild(div)
      expect(shouldDeleteNode(makeKeyboardEvent({key: 'Backspace', currentTarget: div}))).toBe(true)
    })

    it('should return false if the delete key is not pressed', () => {
      const div = document.createElement('div')
      document.body.appendChild(div)
      expect(shouldDeleteNode(makeKeyboardEvent({key: 'a', currentTarget: div}))).toBe(false)
    })

    it('should return false if the element is not empty', () => {
      const div = document.createElement('div')
      div.innerHTML = 'hello world'
      document.body.appendChild(div)
      expect(shouldDeleteNode(makeKeyboardEvent({key: 'Backspace', currentTarget: div}))).toBe(
        false,
      )
    })
  })

  describe('addNewNodeAsNextSibling', () => {
    // requires mocking to much of craft.js
  })

  describe('deleteNodeAndSelecctPrevSibling', () => {
    // requires mocking to much of craft.js
  })

  describe('getArrowNext', () => {
    it('should return ArrowDown and ArrowRight if the document is LTR', () => {
      document.documentElement.dir = 'ltr'
      expect(getArrowNext()).toEqual(['ArrowDown', 'ArrowRight'])
    })

    it('should return ArrowDown and ArrowLeft if the document is RTL', () => {
      document.documentElement.dir = 'rtl'
      expect(getArrowNext()).toEqual(['ArrowDown', 'ArrowLeft'])
    })
  })

  describe('getArrowPrev', () => {
    it('should return ArrowUp and ArrowLeft if the document is LTR', () => {
      document.documentElement.dir = 'ltr'
      expect(getArrowPrev()).toEqual(['ArrowUp', 'ArrowLeft'])
    })

    it('should return ArrowUp and ArrowRight if the document is RTL', () => {
      document.documentElement.dir = 'rtl'
      expect(getArrowPrev()).toEqual(['ArrowUp', 'ArrowRight'])
    })
  })
})
