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

import loadEventListeners from '../loadEventListeners'
import 'jquery'
import 'jqueryui/tabs'

if (!('INST' in window)) window.INST = {}

describe('loadEventListeners', () => {
  let fakeEditor, dispatchEvent
  beforeAll(() => {
    window.INST.editorButtons = [{id: '__BUTTON_ID__'}]

    ENV = {
      context_asset_string: 'course_1',
    }

    fakeEditor = {
      id: 'someId',
      bookmarkMoved: false,
      focus: () => {},
      getContent() {},
      dom: {createHTML: () => "<a href='#'>stub link html</a>"},
      selection: {
        getBookmark: () => ({}),
        getNode: () => ({}),
        getContent: () => ({}),
        moveToBookmark: _prevSelect => (fakeEditor.bookmarkMoved = true),
      },
      addCommand: () => ({}),
      addButton: () => ({}),
      ui: {
        registry: {
          addButton: () => {},
          addMenuButton: () => {},
          addIcon: () => {},
          addNestedMenuItem: () => {},
        },
      },
    }

    dispatchEvent = name => {
      const event = document.createEvent('CustomEvent')
      const eventData = {
        ed: fakeEditor,
        selectNode: '<div></div>',
      }
      event.initCustomEvent(`tinyRCE/${name}`, true, true, eventData)
      document.dispatchEvent(event)
    }
  })

  afterAll(() => {
    window.alert.restore && window.alert.restore()
    window.getComputedStyle.restore && window.getComputedStyle.restore()
    console.log.restore && console.log.restore() // eslint-disable-line no-console
  })
  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('initializes equella plugin', done => {
    expect.assertions(1)
    window.alert = jest.fn()

    loadEventListeners({
      equellaCB() {
        expect(window.alert).toHaveBeenCalledWith(
          'Equella is not properly configured for this account, please notify your system administrator.'
        )
        done()
      },
    })
    dispatchEvent('initEquella')
  })
})
