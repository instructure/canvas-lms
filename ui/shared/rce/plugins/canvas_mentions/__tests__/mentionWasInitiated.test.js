/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import mentionWasInitiated, {spaceCharacters} from '../mentionWasInitiated'

let anchorNode, anchorOffset, selection, triggerChar, selectedNode

const subject = () => mentionWasInitiated(selection, selectedNode, triggerChar)

describe('mentionWasInitiated', () => {
  beforeEach(() => {
    selectedNode = {id: 'foo'}
    triggerChar = '@'
    anchorNode = {wholeText: ''}
    anchorOffset = 2
    selection = {anchorNode, anchorOffset}
  })

  describe('when anchorOffset is falsey', () => {
    beforeEach(() => {
      anchorOffset = undefined
      selection = {anchorNode, anchorOffset}
    })

    it('returns false', () => {
      expect(subject()).toBe(false)
    })
  })

  describe('when anchorNode is falsey', () => {
    beforeEach(() => {
      anchorNode = undefined
    })

    it('returns false', () => {
      expect(subject()).toBe(false)
    })
  })

  describe('when the selected node is the marker', () => {
    beforeEach(() => {
      selectedNode.id = 'mentions-marker'
    })

    it('returns false', () => {
      expect(subject()).toBe(false)
    })
  })

  describe('when the anchor offset is 1', () => {
    beforeEach(() => {
      anchorOffset = 1
      selection = {anchorNode, anchorOffset}
    })

    describe('and the trigger char is the first char in the node', () => {
      beforeEach(() => {
        anchorOffset = 2
        anchorNode.wholeText = `${triggerChar}`
      })

      it('returns true', () => {
        expect(subject()).toBe(true)
      })
    })

    describe('and the trigger char is not the first char in the node', () => {
      beforeEach(() => {
        anchorOffset = 2
        anchorNode.wholeText = '!'
      })

      it('returns false', () => {
        expect(subject()).toBe(false)
      })
    })
  })

  describe('when the proceeding char is a space character', () => {
    describe('space character list', () => {
      it('has a complete list', () => {
        expect(spaceCharacters).toEqual(expect.arrayContaining([' ', '\u00A0', '\uFEFF']))
      })
    })

    describe('and the typed char is the trigger char', () => {
      beforeEach(() => {
        anchorOffset = 2
        anchorNode.wholeText = ` ${triggerChar}`
      })

      it('returns true', () => {
        expect(subject()).toBe(true)
      })
    })

    describe('and the typed char is not the trigger char', () => {
      beforeEach(() => {
        anchorOffset = 2
        anchorNode.wholeText = ' *'
      })

      it('returns false', () => {
        expect(subject()).toBe(false)
      })
    })
  })
})
