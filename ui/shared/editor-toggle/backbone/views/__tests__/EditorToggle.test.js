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

import $ from 'jquery'
import 'jquery-migrate'
import EditorToggle from '../EditorToggle'
import RichContentEditor from '@canvas/rce/RichContentEditor'

jest.mock('@canvas/rce/RichContentEditor', () => ({
  destroyRCE: jest.fn(),
  closeRCE: jest.fn(),
  preloadRemoteModule: jest.fn(),
  callOnRCE: jest.fn(),
}))

describe('EditorToggle', () => {
  let containerDiv

  beforeEach(() => {
    containerDiv = document.createElement('div')
    document.body.appendChild(containerDiv)
  })

  afterEach(() => {
    containerDiv.remove()
  })

  describe('initialization', () => {
    it('initializes textarea container', () => {
      const container = document.createElement('div')
      const et = new EditorToggle($(container))
      expect(et.textAreaContainer[0].contains(et.textArea[0])).toBeTruthy()
    })

    it('passes tinyOptions into getRceOptions', () => {
      const tinyOpts = {width: '100'}
      const initialOpts = {tinyOptions: tinyOpts}
      const editorToggle = new EditorToggle($(containerDiv), initialOpts)
      const opts = editorToggle.getRceOptions()
      expect(opts.tinyOptions).toBe(tinyOpts)
    })

    it('defaults tinyOptions to an empty object if none are given', () => {
      const initialOpts = {someStuff: null}
      const editorToggle = new EditorToggle($(containerDiv), initialOpts)
      const opts = editorToggle.getRceOptions()
      expect(opts.tinyOptions).toEqual({})
    })
  })

  describe('options handling', () => {
    it('does not modify @options.rceOptions after initialization', () => {
      const rceOptions = {
        focus: false,
        otherStuff: '',
      }
      const initialOpts = {
        someStuff: null,
        rceOptions,
      }
      const editorToggle = new EditorToggle($(containerDiv), initialOpts)
      editorToggle.getRceOptions()
      expect(editorToggle.options.rceOptions.focus).toBe(false)
      expect(editorToggle.options.rceOptions.otherStuff).toBe('')
    })

    it('can extend the default RichContentEditor opts with @options.rceOptions', () => {
      const rceOptions = {
        focus: false,
        otherStuff: '',
      }
      const initialOpts = {
        someStuff: null,
        rceOptions,
      }
      const editorToggle = new EditorToggle($(containerDiv), initialOpts)
      const opts = editorToggle.getRceOptions()
      expect(opts.tinyOptions).toBeDefined()
      expect(opts.focus).toBe(false)
      expect(opts.otherStuff).toBe(rceOptions.otherStuff)
    })
  })

  describe('createDone', () => {
    it('does not throw error when editButton does not exist', () => {
      const mockClick = jest.spyOn($.fn, 'click')
      mockClick.mockImplementation(cb => cb())

      EditorToggle.prototype.createDone.call({
        options: {doneText: ''},
        display: () => {},
      })

      expect(mockClick).toHaveBeenCalled()
      mockClick.mockRestore()
    })
  })

  describe('textarea handling', () => {
    it('creates textarea with unique id', () => {
      const ta1 = EditorToggle.prototype.createTextArea()
      const ta2 = EditorToggle.prototype.createTextArea()
      expect(ta1.attr('id')).toBeTruthy()
      expect(ta2.attr('id')).toBeTruthy()
      expect(ta1.attr('id')).not.toBe(ta2.attr('id'))
    })

    it('replaces textarea correctly', () => {
      jest.spyOn(RichContentEditor, 'destroyRCE').mockImplementation()
      jest.spyOn($.fn, 'insertBefore')
      jest.spyOn($.fn, 'remove')
      jest.spyOn($.fn, 'detach')

      const textArea = $('<textarea/>')
      const et = {
        el: $('<div/>'),
        textAreaContainer: $('<div/>'),
        textArea,
        createTextArea: () => ({}),
      }
      EditorToggle.prototype.replaceTextArea.call(et)

      expect($.fn.insertBefore).toHaveBeenCalledWith(et.textAreaContainer)
      expect($.fn.remove).toHaveBeenCalled()
      expect(RichContentEditor.destroyRCE).toHaveBeenCalledWith(textArea)
      expect($.fn.detach).toHaveBeenCalled()
    })
  })

  describe('content handling', () => {
    it('removes MathML when getting content', () => {
      const mathHtml =
        '<div>Math image goes here</div><div class="hidden-readable">MathML goes here</div>'
      containerDiv.innerHTML = mathHtml
      const et = new EditorToggle($(containerDiv))
      expect(et.getContent()).toBe('<div>Math image goes here</div>')
    })

    it('leaves plain text alone when getting content', () => {
      const plainText = 'this is plain text'
      containerDiv.textContent = plainText
      const et = new EditorToggle($(containerDiv))
      expect(et.getContent()).toBe(plainText)
    })
  })
})
