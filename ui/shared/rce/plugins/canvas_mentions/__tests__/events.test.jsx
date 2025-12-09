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
import {
  onSetContent,
  onKeyDown,
  onMouseDown,
  onKeyUp,
  onFocusedUserChange,
  onWindowMouseDown,
  onMentionsExit,
} from '../events'
import {MENTION_MENU_ID, MARKER_ID} from '../constants'

// Mock dependencies at module level - this is evaluated before ES modules are imported
const mockMakeBodyEditable = jest.fn()
const mockInsertMentionFor = jest.fn()

jest.mock('../contentEditable', () => ({
  makeBodyEditable: (...args) => mockMakeBodyEditable(...args),
}))

jest.mock('../edit', () => ({
  insertMentionFor: (...args) => mockInsertMentionFor(...args),
}))

// Mock the MentionDropdown component to avoid tinyMCE dependency
jest.mock('../components/MentionAutoComplete/MentionDropdown', () => () => null)

// Mock constants to provide TRUSTED_MESSAGE_ORIGIN
jest.mock('../constants', () => ({
  ...jest.requireActual('../constants'),
  TRUSTED_MESSAGE_ORIGIN: 'https://canvas.instructure.com',
}))

describe('events', () => {
  let editor

  beforeEach(() => {
    editor = new FakeEditor()
    global.postMessage = jest.fn()
    mockMakeBodyEditable.mockClear()
    mockInsertMentionFor.mockClear()
  })

  afterEach(() => {
    editor.setContent('')
    document.body.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('onSetContent()', () => {
    let event

    const subject = () => onSetContent(event)

    beforeEach(() => {
      event = {
        content: 'hello',
        target: editor,
        paste: false,
        editor,
      }

      // Set up editor with both menu and marker for onMentionsExit to work
      editor.setContent(`<span id="${MARKER_ID}"></span>`)
      // Add menu element outside editor (as real code does)
      const menuEl = document.createElement('span')
      menuEl.id = MENTION_MENU_ID
      document.body.appendChild(menuEl)
    })

    it('calls makeBodyEditable when content does not include marker', () => {
      subject()
      expect(mockMakeBodyEditable).toHaveBeenCalled()
    })

    describe('when content is a paste', () => {
      beforeEach(() => (event.paste = true))

      it('does not call makeBodyEditable', () => {
        subject()
        expect(mockMakeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('when content is the marker', () => {
      beforeEach(() => (event.content = `<span id="${MARKER_ID}"></span>`))

      it('does not call makeBodyEditable', () => {
        subject()
        expect(mockMakeBodyEditable).not.toHaveBeenCalled()
      })
    })
  })

  describe('onKeyDown()', () => {
    let event

    const subject = () => onKeyDown(event)

    beforeEach(() => {
      event = {
        editor,
        which: 1,
        preventDefault: jest.fn(),
      }

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="${MARKER_ID}" contenteditable="true">wes</span>
          </span>
        </div>`,
      )
      editor.selection.select(editor.dom.select(`#${MARKER_ID}`)[0])

      // Add menu element outside editor
      const menuEl = document.createElement('span')
      menuEl.id = MENTION_MENU_ID
      document.body.appendChild(menuEl)
    })

    describe('when the current node is not the marker', () => {
      beforeEach(() => editor.selection.select(editor.dom.select('#test')[0]))

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is tab with active descendant', () => {
      beforeEach(() => {
        event.which = 9 // Tab
        editor.setContent(
          `<div data-testid="fake-body" contenteditable="false">
            <span id="test"> @
              <span id="${MARKER_ID}" contenteditable="true" aria-activedescendant="user-1">wes</span>
            </span>
          </div>`,
        )
        editor.selection.select(editor.dom.select(`#${MARKER_ID}`)[0])
      })

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })

      it('prevents default behavior', () => {
        subject()
        expect(event.preventDefault).toHaveBeenCalled()
      })
    })

    describe('when the key is "enter" with active descendant', () => {
      beforeEach(() => {
        event.which = 13 // Enter
        editor.setContent(
          `<div data-testid="fake-body" contenteditable="false">
            <span id="test"> @
              <span id="${MARKER_ID}" contenteditable="true" aria-activedescendant="user-1">wes</span>
            </span>
          </div>`,
        )
        editor.selection.select(editor.dom.select(`#${MARKER_ID}`)[0])
      })

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })

      it('prevents default behavior', () => {
        subject()
        expect(event.preventDefault).toHaveBeenCalled()
      })
    })

    describe('when the key is "backspace" with offset 1', () => {
      beforeEach(() => {
        event.which = 8 // Backspace
        editor.selection.setRng({endOffset: 1, startOffset: 1})
      })

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })

      it('removes the menu element from the DOM', () => {
        expect(document.querySelector(`span#${MENTION_MENU_ID}`)).not.toBeNull()
        subject()
        expect(document.querySelector(`span#${MENTION_MENU_ID}`)).toBeNull()
      })
    })

    describe('when the key is "backspace" with offset 0', () => {
      beforeEach(() => {
        event.which = 8 // Backspace
        editor.selection.setRng({endOffset: 0, startOffset: 0})
      })

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is backspace with offset > 1', () => {
      beforeEach(() => {
        event.which = 8 // Backspace
        editor.selection.setRng({endOffset: 2, startOffset: 2})
      })

      it('does not call makeBodyEditable (stays in mentions mode)', () => {
        subject()
        expect(mockMakeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('with mentions suggestion navigation events', () => {
      describe('when the key is "up"', () => {
        beforeEach(() => {
          event.which = 38 // Up arrow
        })

        it('does not call makeBodyEditable (stays in mentions mode)', () => {
          subject()
          expect(mockMakeBodyEditable).not.toHaveBeenCalled()
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('broadcasts the navigation message to windows', () => {
          subject()
          expect(global.postMessage).toHaveBeenCalledTimes(2)
          expect(global.postMessage).toHaveBeenCalledWith(
            {
              subject: 'mentions.NavigationEvent',
              value: 'UpArrow',
            },
            'https://canvas.instructure.com',
          )
        })
      })

      describe('when the key is "down"', () => {
        beforeEach(() => {
          event.which = 40 // Down arrow
        })

        it('does not call makeBodyEditable (stays in mentions mode)', () => {
          subject()
          expect(mockMakeBodyEditable).not.toHaveBeenCalled()
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('broadcasts the navigation message to windows', () => {
          subject()
          expect(global.postMessage).toHaveBeenCalledTimes(2)
          expect(global.postMessage).toHaveBeenCalledWith(
            {
              subject: 'mentions.NavigationEvent',
              value: 'DownArrow',
            },
            'https://canvas.instructure.com',
          )
        })
      })

      describe('when the key is "tab" (selection with focused user)', () => {
        beforeEach(() => {
          event.which = 9 // Tab
          // Set up a focused user first
          onFocusedUserChange(
            {
              ariaActiveDescendantId: '#foo',
              name: 'Test User',
              _id: '12345',
            },
            editor,
          )
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('inserts the mention for the focused user', () => {
          subject()
          expect(mockInsertMentionFor).toHaveBeenCalled()
        })
      })

      describe('when the key is "enter" (selection with focused user)', () => {
        beforeEach(() => {
          event.which = 13 // Enter
          // Set up a focused user first
          onFocusedUserChange(
            {
              ariaActiveDescendantId: '#foo',
              name: 'Test User',
              _id: '12345',
            },
            editor,
          )
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('inserts the mention for the focused user', () => {
          subject()
          expect(mockInsertMentionFor).toHaveBeenCalled()
        })
      })

      describe('when the key is "esc"', () => {
        beforeEach(() => {
          event.which = 27 // Escape key
        })

        it('prevents default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('does not broadcast navigation message', () => {
          subject()
          expect(global.postMessage).not.toHaveBeenCalled()
        })

        it('removes the mentions menu from the DOM', () => {
          expect(document.querySelector(`span#${MENTION_MENU_ID}`)).not.toBeNull()
          subject()
          expect(document.querySelector(`span#${MENTION_MENU_ID}`)).toBeNull()
        })
      })
    })
  })

  describe('onKeyUp()', () => {
    let event

    const subject = () => onKeyUp(event)

    beforeEach(() => {
      event = {
        editor,
        which: 1,
      }

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="${MARKER_ID}" contenteditable="true">wes</span>
          </span>
        </div>`,
      )

      editor.selection.select(editor.dom.select(`#${MARKER_ID}`)[0])
      editor.setSelectedNode(editor.dom.select(`#${MARKER_ID}`)[0])
    })

    it('broadcasts the input change message to windows', () => {
      subject()
      expect(global.postMessage).toHaveBeenCalledTimes(2)
      expect(global.postMessage).toHaveBeenCalledWith(
        {
          subject: 'mentions.InputChangeEvent',
          value: 'wes',
        },
        'https://canvas.instructure.com',
      )
    })

    describe('when the mentions marker is not the current node', () => {
      beforeEach(() => {
        editor.selection.select(editor.dom.select('#test')[0])
      })

      it('does not broadcast the message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })

    describe('when the "tab" key is pressed', () => {
      beforeEach(() => (event.which = 9))

      it('does not broadcast an input change message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })

    describe('when the "enter" key is pressed', () => {
      beforeEach(() => (event.which = 13))

      it('does not broadcast an input change message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })
  })

  describe('onMouseDown()', () => {
    let event

    const subject = () => onMouseDown(event)

    beforeEach(() => {
      event = {
        editor,
        target: {},
      }

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="${MARKER_ID}" contenteditable="true">wes</span>
          </span>
        </div>`,
      )

      // Add menu element outside editor for onMentionsExit to work
      const menuEl = document.createElement('span')
      menuEl.id = MENTION_MENU_ID
      document.body.appendChild(menuEl)
    })

    describe('when the current target is the marker', () => {
      beforeEach(() => {
        event.target.id = MARKER_ID
      })

      it('does not call makeBodyEditable (stays in mentions mode)', () => {
        subject()
        expect(mockMakeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('when the current target is not the marker', () => {
      beforeEach(() => (event.target.id = undefined))

      it('calls makeBodyEditable to exit mentions mode', () => {
        subject()
        expect(mockMakeBodyEditable).toHaveBeenCalled()
      })
    })
  })

  describe('onFocusedUserChange()', () => {
    let focusedUser

    const subject = () => onFocusedUserChange(focusedUser, editor)

    beforeEach(() => {
      focusedUser = {
        ariaActiveDescendantId: '#foo',
        name: 'Test User',
        _id: '12345',
      }

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="${MARKER_ID}" contenteditable="true">wes</span>
          </span>
        </div>`,
      )

      editor.selection.select(editor.dom.select(`#${MARKER_ID}`)[0])
    })

    it('sets the active descendant attribute', () => {
      subject()
      expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('aria-activedescendant')).toEqual(
        '#foo',
      )
    })

    it('sets the data-userId attribute', () => {
      subject()
      expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('data-userId')).toEqual('12345')
    })

    it('sets the data-displayName attribute', () => {
      subject()
      expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('data-displayname')).toEqual(
        'Test User',
      )
    })

    describe('when the focused user is blank', () => {
      beforeEach(() => (focusedUser = undefined))

      it('sets the active descendant attribute to an empty string', () => {
        subject()
        expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('aria-activedescendant')).toEqual(
          '',
        )
      })

      it('sets the data-displayname attribute to an empty string', () => {
        subject()
        expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('data-displayname')).toEqual('')
      })

      it('sets the data-userId attribute to an empty string', () => {
        subject()
        expect(editor.dom.select(`#${MARKER_ID}`)[0].getAttribute('data-userId')).toEqual('')
      })
    })
  })

  describe('onWindowMouseDown()', () => {
    let event
    const subject = () => onWindowMouseDown(event)

    beforeEach(() => {
      event = {
        editor,
        target: {},
      }
      // Set up editor content with marker
      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="${MARKER_ID}" contenteditable="true">wes</span>
          </span>
        </div>`,
      )
      // Add elements to document.body for click target detection
      const outsideEl = document.createElement('div')
      outsideEl.id = 'outsideid'
      document.body.appendChild(outsideEl)

      const menuEl = document.createElement('span')
      menuEl.id = MENTION_MENU_ID
      const insideEl = document.createElement('div')
      insideEl.id = 'testid'
      menuEl.appendChild(insideEl)
      document.body.appendChild(menuEl)
    })

    it('removes the MentionsMenu when click is outside the menu', () => {
      event.target = document.getElementById('outsideid')
      subject()
      expect(document.getElementById(MENTION_MENU_ID)).toBeNull()
    })

    it('does not remove the MentionsMenu when click is inside the menu', () => {
      event.target = document.getElementById('testid')
      subject()
      expect(document.getElementById(MENTION_MENU_ID)).not.toBeNull()
    })
  })
})
