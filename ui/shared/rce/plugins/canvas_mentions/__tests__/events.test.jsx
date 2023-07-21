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

import {makeBodyEditable} from '../contentEditable'
import {insertMentionFor} from '../edit'
import FakeEditor from './FakeEditor'
import {
  onSetContent,
  onKeyDown,
  onMouseDown,
  onKeyUp,
  onFocusedUserChange,
  onWindowMouseDown,
} from '../events'
import {MENTION_MENU_ID} from '../constants'
import ReactDOM from 'react-dom'

jest.mock('../contentEditable', () => ({
  makeBodyEditable: jest.fn(),
}))

jest.mock('../edit', () => ({
  insertMentionFor: jest.fn(),
}))

jest.mock('../constants', () => ({
  ...jest.requireActual('../constants'),
  TRUSTED_MESSAGE_ORIGIN: 'https://canvas.instructure.com',
}))

jest.mock('react-dom', () => ({
  render: jest.fn(),
  unmountComponentAtNode: jest.fn(),
}))

jest.mock('../components/MentionAutoComplete/MentionDropdown')

describe('events', () => {
  let editor

  beforeEach(() => {
    editor = new FakeEditor()
  })

  afterEach(() => {
    editor.setContent('')
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

      editor.setContent('<span id="mention-menu"></span><span id="mentions-marker"></span>')
    })

    afterEach(() => {
      document.body.innerHTML = ''
    })

    it('makes the body editable', () => {
      subject()
      expect(makeBodyEditable).toHaveBeenCalled()
    })

    describe('when content is a paste', () => {
      beforeEach(() => (event.paste = true))

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('when content is the marker', () => {
      beforeEach(() => (event.content = '<span id="mentions-marker"></span>'))

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).not.toHaveBeenCalled()
      })

      it('mounts the dropdown component', () => {
        jest.spyOn(document, 'querySelector').mockImplementation(() => {
          return false
        })
        subject()
        expect(ReactDOM.render).toHaveBeenCalled()
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
        preventDefault: () => {},
      }

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
            <span id="mention-menu"></span>
          </span>
        </div>`
      )

      editor.selection.select(editor.dom.select('#mentions-marker')[0])
    })

    afterEach(() => (document.body.innerHTML = ''))

    describe('when the current node is not the marker', () => {
      beforeEach(() => editor.selection.select(editor.dom.select('#test')[0]))

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is tab', () => {
      beforeEach(() => {
        event.which = 9

        editor.setContent(
          `<div data-testid="fake-body" contenteditable="false">
            <span id="test"> @
              <span id="mentions-marker" contenteditable="true" aria-activedescendant="test"->wes</span>
              <span id="mention-menu"></span>
            </span>
          </div>`
        )
      })

      afterEach(() => (document.body.innerHTML = ''))

      it('does make the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the the key is "enter"', () => {
      beforeEach(() => {
        event.which = 13

        editor.setContent(
          `<div data-testid="fake-body" contenteditable="false">
            <span id="test"> @
              <span id="mentions-marker" contenteditable="true" aria-activedescendant="test"->wes</span>
              <span id="mention-menu"></span>
            </span>
          </div>`
        )
      })

      afterEach(() => (document.body.innerHTML = ''))

      it('does make the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is "backspace" with offset 1', () => {
      let mountElement

      beforeEach(() => {
        event.which = 8
        editor.selection.setRng({endOffset: 1, startOffset: 1})

        mountElement = document.createElement('span')
        mountElement.id = 'mention-menu'
        document.body.appendChild(mountElement)
      })

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })

      it('closes the MentionsMenu', () => {
        subject()
        expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalled()
      })
    })

    describe('when the key is "backspace" with offset 0', () => {
      beforeEach(() => {
        event.which = 8
        editor.selection.setRng({endOffset: 0, startOffset: 0})
      })

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is backspace with offset > 1', () => {
      beforeEach(() => {
        event.which = 8
        editor.selection.setRng({endOffset: 2, startOffset: 2})
      })

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('with mentions suggestion navigation events', () => {
      let expectedValue, expectedMessageType

      function examplesForMentionsEvents() {
        it('does not make the body editable', () => {
          subject()
          expect(makeBodyEditable).not.toHaveBeenCalled()
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('broadcasts the message to the tiny and main windows', () => {
          subject()
          expect(global.postMessage).toHaveBeenCalledTimes(2)
          expect(global.postMessage).toHaveBeenCalledWith(
            {
              subject: expectedMessageType,
              value: expectedValue,
            },
            'https://canvas.instructure.com'
          )
        })
      }

      describe('when the key is "up"', () => {
        beforeEach(() => {
          event.which = 38

          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          expectedValue = 'UpArrow'
          expectedMessageType = 'mentions.NavigationEvent'
        })

        examplesForMentionsEvents()
      })

      describe('when the key is "down"', () => {
        beforeEach(() => {
          event.which = 40

          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          expectedValue = 'DownArrow'
          expectedMessageType = 'mentions.NavigationEvent'
        })

        examplesForMentionsEvents()
      })

      describe('when the key is "tab"', () => {
        beforeEach(() => {
          event.which = 9

          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          expectedValue = 'Tab'
          expectedMessageType = 'mentions.SelectionEvent'

          onFocusedUserChange(
            {
              ariaActiveDescendantId: '#foo',
              name: 'Test User',
              _id: '12345',
            },
            editor
          )
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('inserts the mention', () => {
          subject()
          expect(insertMentionFor).toHaveBeenCalled()
        })
      })

      describe('when the key is "enter"', () => {
        beforeEach(() => {
          event.which = 13

          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          expectedValue = 'Enter'
          expectedMessageType = 'mentions.SelectionEvent'

          onFocusedUserChange(
            {
              ariaActiveDescendantId: '#foo',
              name: 'Test User',
              _id: '12345',
            },
            editor
          )
        })

        it('prevents the event default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('inserts the mention', () => {
          subject()
          expect(insertMentionFor).toHaveBeenCalled()
        })
      })

      describe('when the key is "esc"', () => {
        beforeEach(() => {
          event.which = 27
          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()
        })

        it('prevents default', () => {
          subject()
          expect(event.preventDefault).toHaveBeenCalled()
        })

        it('does not broadcast the message', () => {
          subject()
          expect(global.postMessage).not.toHaveBeenCalled()
        })

        it('unmounts the component', () => {
          subject()
          expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalledTimes(1)
        })

        it('removes the mount element', () => {
          subject()
          expect(document.getElementById('mention-menu')).toBeNull()
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

      global.postMessage = jest.fn()

      editor.setContent(
        `<div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )

      editor.selection.select(editor.dom.select('#mentions-marker')[0])
      editor.setSelectedNode(editor.dom.select('#mentions-marker')[0])
    })

    it('broadcasts the message to the tiny and main windows', () => {
      subject()
      expect(global.postMessage).toHaveBeenCalledTimes(2)
      expect(global.postMessage).toHaveBeenCalledWith(
        {
          subject: 'mentions.InputChangeEvent',
          value: 'wes',
        },
        'https://canvas.instructure.com'
      )
    })

    describe('when the mentions marker is not the current node', () => {
      beforeEach(() => {
        editor.selection.select(editor.dom.select('#test')[0])
      })

      it('does not broadcast the message', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })

    describe('when the "tab" key is pressed', () => {
      beforeEach(() => (event.which = 9))

      it('does not broadcast an input change method', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
        expect(global.postMessage).not.toHaveBeenCalled()
      })
    })

    describe('when the "enter" key is pressed', () => {
      beforeEach(() => (event.which = 13))

      it('does not broadcast an input change method', () => {
        subject()
        expect(global.postMessage).not.toHaveBeenCalled()
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
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
          <span id="mention-menu"></span>
        </div>`
      )
    })

    describe('when the current target is the marker', () => {
      beforeEach(() => {
        event.target.id = 'mentions-marker'
      })

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('when the current target is not the marker', () => {
      beforeEach(() => (event.target.id = undefined))

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
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
            <span id="mentions-marker" contenteditable="true">wes</span>
          </span>
        </div>`
      )

      editor.selection.select(editor.dom.select('#mentions-marker')[0])
    })

    it('sets the active descendant attribute', () => {
      subject()
      expect(
        editor.dom.select('#mentions-marker')[0].getAttribute('aria-activedescendant')
      ).toEqual('#foo')
    })

    it('sets the data-userId attribute', () => {
      subject()
      expect(editor.dom.select('#mentions-marker')[0].getAttribute('data-userId')).toEqual('12345')
    })

    it('sets the data-displayName attribute', () => {
      subject()
      expect(editor.dom.select('#mentions-marker')[0].getAttribute('data-displayName')).toEqual(
        'Test User'
      )
    })

    describe('when the focused user is blank', () => {
      beforeEach(() => (focusedUser = undefined))

      it('sets the active descendant attribute to an empty string', () => {
        subject()
        expect(
          editor.dom.select('#mentions-marker')[0].getAttribute('aria-activedescendant')
        ).toEqual('')
      })

      it('sets the data-displayname attribute to an empty string', () => {
        subject()
        expect(editor.dom.select('#mentions-marker')[0].getAttribute('data-displayName')).toEqual(
          ''
        )
      })

      it('sets the data-userId attribute to an empty string', () => {
        subject()
        expect(editor.dom.select('#mentions-marker')[0].getAttribute('data-userId')).toEqual('')
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
      const content = `<div id="outsideid"> </div>
      <div data-testid="fake-body" contenteditable="false">
          <span id="test"> @
            <span id="mentions-marker" contenteditable="true">wes</span>
            <span id="${MENTION_MENU_ID}"><div id="testid"></div></span>
          </span>
        </div>`
      editor.setContent(content)
      document.body.innerHTML = content
    })

    afterEach(() => {
      document.body.innerHTML = ''
    })

    it('closes the MentionsMenu when click is outside the menu', () => {
      event.target = document.getElementById('outsideid')
      subject()
      expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalledTimes(1)
    })

    it('does not close the MentionsMenu when click is inside the menu', () => {
      event.target = document.getElementById('testid')
      subject()
      expect(ReactDOM.unmountComponentAtNode).not.toHaveBeenCalled()
    })
  })
})
