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

import FakeEditor from './FakeEditor'
import {screen} from '@testing-library/dom'
import {makeMarkerEditable, makeBodyEditable} from '../contentEditable'

jest.mock('react-dom')

describe('contentEditable', () => {
  describe('makeMarkerEditable()', () => {
    let editor

    const subject = () => makeMarkerEditable(editor, '#mentions-marker')

    beforeEach(() => {
      editor = new FakeEditor()
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="true">
          <span id="test"> @
            <span data-testid="mentions-marker" id="mentions-marker">wes</span>
          </span>
        </div>`
      )
    })

    afterEach(() => {
      editor.setContent('')
      jest.resetAllMocks()
    })

    it('sets contenteditable to false on the body', () => {
      subject()
      expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
    })

    it('sets contenteditable to true on the marker', () => {
      subject()
      expect(screen.getByTestId('mentions-marker').getAttribute('contenteditable')).toEqual('true')
    })

    it('moves the cursor to the editable span', () => {
      editor.selection.setCursorLocation = jest.fn()
      subject()
      expect(editor.selection.setCursorLocation).toHaveBeenCalled()
    })
  })

  describe('makeBodyEditable()', () => {
    let editor

    const subject = () => makeBodyEditable(editor, '#mentions-marker')

    beforeEach(() => {
      editor = new FakeEditor()
      editor.selection.getBookmark = jest.fn()
      editor.selection.moveToBookmark = jest.fn()

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span data-testid="mentions-marker" id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )
    })

    afterEach(() => {
      editor.setContent('')
    })

    it('sets contenteditable to true on the body', () => {
      subject()
      expect(editor.getBody().getAttribute('contenteditable')).toEqual('true')
    })

    it('gets the current cursor position', () => {
      subject()
      expect(editor.selection.getBookmark).toHaveBeenCalled()
    })

    it('sets the cursor position', () => {
      subject()
      expect(editor.selection.moveToBookmark).toHaveBeenCalled()
    })
  })
})
