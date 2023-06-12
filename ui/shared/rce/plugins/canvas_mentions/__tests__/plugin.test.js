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
// FYI, there is a new-improved FakeEditor at@instructure/canvas-rce/src/rce/__tests__/FakeEditor
// but I failed to get this and other unit tests in canvas_mentions/__tests__ to pass with it
// Rather than spend days trying to figure that out, I left the old mock around to use here (and only here)
import FakeEditor from './FakeEditor'
import {screen} from '@testing-library/dom'
import {KEY_CODES} from '../constants'
import {onFocusedUserChange, onMentionsExit} from '../events'

const mockAnchorOffset = 2
const mockAnchorWholeText = ''
const mockAnchorNode = {wholeText: mockAnchorWholeText}

jest.mock('@instructure/canvas-rce/es/rce/tinyRCE', () => ({
  create: jest.fn(),
  PluginManager: {
    add: jest.fn(),
  },
  plugins: {
    CanvasMentionsPlugin: {},
  },
  activeEditor: {
    selection: {
      getSel: () => ({
        anchorOffset: mockAnchorOffset,
        anchorNode: mockAnchorNode,
      }),
    },
  },
}))

jest.mock('../events', () => ({
  ...jest.requireActual('../events'),
  onMentionsExit: jest.fn(),
}))

jest.mock('../components/MentionAutoComplete/MentionDropdown')
jest.mock('react-dom')

afterEach(() => {
  jest.restoreAllMocks()
})

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
    global.tinymce = {
      activeEditor: editor,
    }
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

  function sharedExamplesForEventHandlers(subject, markerContent = 'wes') {
    it('makes the body contenteditable', () => {
      subject()
      expect(editor.getBody().getAttribute('contenteditable')).toEqual('true')
    })

    it('removes contenteditable from the marker span', () => {
      subject()
      expect(screen.getByText(markerContent).getAttribute('contenteditable')).toBeNull()
    })

    it('removes the ID from the marker span', () => {
      subject()
      expect(screen.getByText(markerContent).id).toEqual('')
    })
  }

  describe('SetContent', () => {
    let insertionContent

    const subject = () => editor.fire('SetContent', {content: insertionContent, target: editor})

    beforeEach(() => {
      onFocusedUserChange({name: 'wes', _id: 1})

      insertionContent = '<h1>Hello!</h1>'
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
          </span>
          <span id="mention-menu"></span>
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

  describe('KeyUp', () => {
    let which

    const subject = () => editor.fire('KeyUp', {which, editor})

    beforeEach(() => {
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )

      editor.selection.select(editor.dom.select('#mentions-marker')[0])
      editor.setSelectedNode(editor.dom.select('#mentions-marker')[0])

      global.postMessage = jest.fn()
    })

    describe('when the event is for a non-navigation key', () => {
      beforeEach(() => (which = 69))

      it('broadcasts the message', () => {
        subject()
        expect(global.postMessage).toHaveBeenCalledTimes(2)
      })
    })

    describe('when the event is for a navigation key', () => {
      beforeEach(() => (which = KEY_CODES.up))

      it('does not broadcast a message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })

    describe('when the marker node is not selected', () => {
      beforeEach(() => editor.selection.select(editor.dom.select('#test')[0]))

      it('does not broadcast a message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })
  })

  describe('KeyDown', () => {
    let which, preventDefault

    const subject = () => editor.fire('KeyDown', {which, editor, preventDefault})

    beforeEach(() => {
      which = 1
      preventDefault = jest.fn()
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
            <span id="mention-menu"></span>
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

      function examplesForMentionEvents() {
        it('prevents default', () => {
          subject()
          expect(preventDefault).toHaveBeenCalled()
        })

        it('broadcasts the event via postMessage', () => {
          subject()
          expect(global.postMessage).toHaveBeenCalled()
        })
      }

      it('does not make the body contenteditable', () => {
        subject()
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })

      describe('and the key pressed was "up"', () => {
        beforeEach(() => {
          which = KEY_CODES.up
          global.postMessage = jest.fn()
        })

        examplesForMentionEvents()
      })

      describe('and the key pressed was "down"', () => {
        beforeEach(() => {
          which = KEY_CODES.down
          global.postMessage = jest.fn()
        })

        examplesForMentionEvents()
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

      describe('with the key down for an "enter"', () => {
        beforeEach(() => {
          which = 13
          editor.setContent(
            `<div data-testid="fake-body" contenteditable="false">
              <span id="test"> @<span id="mentions-marker" contenteditable="true" aria-activedescendant="test" data-userid="123" data-displayname="Test">wes</span>
                <span id="mention-menu"></span>
              </span>
            </div>`
          )
        })

        sharedExamplesForEventHandlers(subject, '@wes')
      })
    })
  })

  describe('MouseDown', () => {
    let target

    const subject = () => editor.fire('MouseDown', {editor, target})

    beforeEach(() => {
      target = {id: ''}
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
            <span id="mention-menu"></span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForEventHandlers(subject)

    describe('when the target of the click is the marker', () => {
      beforeEach(() => (target = {id: 'mentions-marker'}))

      it('does not make the body contenteditable', () => {
        subject()
        expect(editor.getBody().getAttribute('contenteditable')).toEqual('false')
      })
    })
  })

  function sharedExamplesForHandlersThatUnmount(subject) {
    it('calls "onMentionExit"', () => {
      subject()
      expect(onMentionsExit).toHaveBeenCalledWith(editor)
    })
  }

  describe('Remove', () => {
    const subject = () => editor.fire('Remove', {target: editor})

    beforeEach(() => {
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
            <span id="mention-menu"></span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForHandlersThatUnmount(subject)

    it('removes onWindowMouseDown listener', () => {
      window.removeEventListener = jest.fn()
      subject()
      expect(window.removeEventListener).toHaveBeenCalledTimes(1)
    })
  })

  describe('ViewChange', () => {
    const subject = () => editor.fire('ViewChange', {target: editor})

    beforeEach(() => {
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @<span id="mentions-marker" contenteditable="true">wes</span>
            <span id="mention-menu"></span>
          </span>
        </div>`
      )
      editor.selection.select(editor.dom.select('#test')[0])
    })

    sharedExamplesForHandlersThatUnmount(subject)
  })
})
