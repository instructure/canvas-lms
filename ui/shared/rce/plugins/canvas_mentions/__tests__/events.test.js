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
import FakeEditor from '@instructure/canvas-rce/src/rce/plugins/shared/__tests__/FakeEditor'
import {onSetContent, onKeyDown, onMouseDown, onKeyUp, onActiveDescendantChange} from '../events'
import ReactDOM from 'react-dom'

jest.mock('../contentEditable', () => ({
  makeBodyEditable: jest.fn()
}))

jest.mock('../constants', () => ({
  ...jest.requireActual('../constants'),
  TRUSTED_MESSAGE_ORIGIN: 'https://canvas.instructure.com'
}))

jest.mock('react-dom', () => ({
  render: jest.fn(),
  unmountComponentAtNode: jest.fn()
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
        editor
      }
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
        which: 1
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

    afterEach(() => (document.body.innerHTML = ''))

    describe('when the current node is not the marker', () => {
      beforeEach(() => editor.selection.select(editor.dom.select('#test')[0]))

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the the key is "enter"', () => {
      beforeEach(() => (event.which = 13))

      it('does make the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })

    describe('when the key is "backspace" with offset 1', () => {
      beforeEach(() => {
        event.which = 8
        editor.selection.setRng({endOffset: 1, startOffset: 1})
      })

      it('makes the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
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
              messageType: expectedMessageType,
              value: expectedValue
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

      describe('when the key is "enter"', () => {
        beforeEach(() => {
          event.which = 13

          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          expectedValue = 'Enter'
          expectedMessageType = 'mentions.SelectionEvent'

          onActiveDescendantChange('#foo', editor)
        })

        examplesForMentionsEvents()
      })

      describe('when the key is "esc"', () => {
        let mountElement

        beforeEach(() => {
          event.which = 27
          event.preventDefault = jest.fn()
          global.postMessage = jest.fn()

          mountElement = document.createElement('span')
          mountElement.id = 'mention-menu'
          document.body.appendChild(mountElement)
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
          expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalledWith(mountElement)
        })

        it('removes the mount element', () => {
          subject()
          expect(document.getElementById(mountElement.id)).toBeNull()
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
        which: 1
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
          messageType: 'mentions.InputChangeEvent',
          value: 'wes'
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
        target: {}
      }
    })

    describe('when the current target is the marker', () => {
      beforeEach(() => (event.target.id = 'mentions-marker'))

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).not.toHaveBeenCalled()
      })
    })

    describe('when the current target is not the marker', () => {
      beforeEach(() => (event.target.id = undefined))

      it('does not make the body editable', () => {
        subject()
        expect(makeBodyEditable).toHaveBeenCalled()
      })
    })
  })

  describe('onActiveDescendantChange()', () => {
    let activeDescendant

    const subject = () => onActiveDescendantChange(activeDescendant, editor)

    beforeEach(() => {
      activeDescendant = '#foo'

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

    describe('when the active descendant is blank', () => {
      beforeEach(() => (activeDescendant = undefined))

      it('sets the active descendant attribute to an empty string', () => {
        subject()
        expect(
          editor.dom.select('#mentions-marker')[0].getAttribute('aria-activedescendant')
        ).toEqual('')
      })
    })
  })
})
