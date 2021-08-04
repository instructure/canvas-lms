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

import tinymce from '@instructure/canvas-rce/es/rce/tinyRCE'
import * as plugin from '../plugin'
import FakeEditor from '@instructure/canvas-rce/src/rce/plugins/shared/__tests__/FakeEditor'
import {screen} from '@testing-library/dom'

const mockAnchorOffset = 2
const mockAnchorWholeText = ''
const mockAnchorNode = {wholeText: mockAnchorWholeText}

jest.mock('@instructure/canvas-rce/es/rce/tinyRCE', () => ({
  create: jest.fn(),
  PluginManager: {
    add: jest.fn()
  },
  plugins: {
    CanvasMentionsPlugin: {}
  },
  activeEditor: {
    selection: {
      getSel: () => ({
        anchorOffset: mockAnchorOffset,
        anchorNode: mockAnchorNode
      })
    }
  }
}))

describe('plugin', () => {
  it('has a name', () => {
    expect(plugin.name).toEqual('canvas_mentions')
  })

  it('creates the plugin', () => {
    expect(tinymce.create).toHaveBeenCalledWith(
      'tinymce.plugins.CanvasMentionsPlugin',
      expect.anything()
    )
  })

  it('registers the plugin', () => {
    expect(tinymce.PluginManager.add).toHaveBeenCalledWith('canvas_mentions', expect.anything())
  })
})

describe('pluginDefinition', () => {
  let editor
  beforeEach(() => {
    editor = new FakeEditor()
    plugin.pluginDefinition.init(editor)
  })

  afterEach(() => editor.setContent(''))

  describe('input', () => {
    beforeEach(() => {
      editor.setContent('<span id="test"></span>')
      editor.selection.select(editor.dom.select('#test')[0])
    })

    const sharedExamplesForTriggeredMentions = () => {
      it('renders a the mentions marker', async () => {
        editor.fire('input', {}, editor)
        expect(screen.getByTestId('mentions-marker')).toBeInTheDocument()
      })

      it('makes the marker contenteditable', () => {
        editor.fire('input', {}, editor)
        expect(screen.getByTestId('mentions-marker').getAttribute('contenteditable')).toEqual(
          'true'
        )
      })

      it('removes contenteditable from the body', () => {
        editor.fire('input', {}, editor)
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })
    }

    describe('when an "inline" mention is triggered', () => {
      beforeEach(() => {
        editor.setContent(
          '<div data-testid="fake-body" contenteditable="true"><span id="test"> @</span></div>'
        )
        editor.selection.select(editor.dom.select('#test')[0])
        editor.selection.setAnchorOffset(2)
      })

      sharedExamplesForTriggeredMentions()
    })

    describe('when a "starting" mention is triggered', () => {
      beforeEach(() => {
        editor.setContent(
          '<div data-testid="fake-body" contenteditable="true"><span id="test">@</span></div>'
        )
        editor.selection.select(editor.dom.select('#test')[0])
        editor.selection.setAnchorOffset(1)
      })

      sharedExamplesForTriggeredMentions()
    })
  })

  function sharedExamplesForEventHandlers(subject) {
    it('makes the body contenteditable', () => {
      subject()
      expect(editor.getBody().getAttribute('contenteditable')).toEqual('true')
    })

    it('removes contenteditable from the marker span', () => {
      subject()
      expect(screen.getByText('wes').getAttribute('contenteditable')).toBeNull()
    })

    it('removes the ID from the marker span', () => {
      subject()
      expect(screen.getByText('wes').id).toEqual('')
    })
  }

  describe('SetContent', () => {
    let insertionContent

    const subject = () => editor.fire('SetContent', {content: insertionContent, target: editor})

    beforeEach(() => {
      insertionContent = '<h1>Hello!</h1>'
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForEventHandlers(subject)

    describe('when the content being inserted includes the marker', () => {
      beforeEach(() => {
        insertionContent = '<span id="mentions-marker" contenteditable="true"></span>'
      })

      it('does not make the body contenteditable', () => {
        subject()
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })
    })
  })

  describe('KeyDown', () => {
    let which

    const subject = () => editor.fire('KeyDown', {which, editor})

    beforeEach(() => {
      which = 1
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForEventHandlers(subject)

    describe('when the active node is the marker', () => {
      beforeEach(() => {
        editor.selection.select(editor.dom.select('#mentions-marker')[0])
      })

      it('does not make the body contenteditable', () => {
        subject()
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })

      describe('with the key down for a "backspace" deleting the trigger character', () => {
        beforeEach(() => {
          which = 8
          editor.selection.setRng({endOffset: 1, startOffset: 1})
        })

        sharedExamplesForEventHandlers(subject)
      })

      describe('with the key down for a "backspace" not deleting the trigger char', () => {
        beforeEach(() => {
          which = 8
          editor.selection.setRng({endOffset: 1, startOffset: 2})
        })

        it('does not make the body contenteditable', () => {
          subject()
          expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
        })
      })

      describe('whith the key down for an "enter"', () => {
        beforeEach(() => (which = 13))

        sharedExamplesForEventHandlers(subject)
      })
    })
  })

  describe('MouseDown', () => {
    let currentTarget

    const subject = () => editor.fire('MouseDown', {editor, currentTarget})

    beforeEach(() => {
      currentTarget = {id: ''}
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForEventHandlers(subject)

    describe('when the target of the click is the marker', () => {
      beforeEach(() => (currentTarget = {id: 'mentions-marker'}))

      it('does not make the body contenteditable', () => {
        subject()
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })
    })
  })
})
