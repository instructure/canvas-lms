/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import EquationEditorView from 'compiled/views/tinymce/EquationEditorView'
import Links from 'tinymce_plugins/instructure_links/links'
import InsertUpdateImageView from 'compiled/views/tinymce/InsertUpdateImageView'
import loadEventListeners from 'jsx/shared/rce/loadEventListeners'
import 'jquery'
import 'jqueryui/tabs'
import 'INST'

let fakeEditor

QUnit.module('loadEventListeners', {
  setup() {
    window.INST.maxVisibleEditorButtons = 10
    window.INST.editorButtons = [{id: '__BUTTON_ID__'}]
    fakeEditor = {
      id: 'someId',
      bookmarkMoved: false,
      focus: () => {},
      dom: {createHTML: () => "<a href='#'>stub link html</a>"},
      selection: {
        getBookmark: () => ({}),
        getNode: () => ({}),
        getContent: () => ({}),
        moveToBookmark: prevSelect => (fakeEditor.bookmarkMoved = true)
      },
      addCommand: () => ({}),
      addButton: () => ({})
    }
    this.dispatchEvent = name => {
      const event = document.createEvent('CustomEvent')
      const eventData = {
        ed: fakeEditor,
        selectNode: '<div></div>'
      }
      event.initCustomEvent(`tinyRCE/${name}`, true, true, eventData)
      document.dispatchEvent(event)
    }
  },
  teardown() {
    window.alert.restore && window.alert.restore()
    console.log.restore && console.log.restore()
  }
})

test('initializes equation editor plugin', function(assert) {
  const done = assert.async()
  loadEventListeners({
    equationCB: view => {
      ok(view instanceof EquationEditorView)
      equal(view.$editor.selector, '#someId')
      done()
    }
  })
  return this.dispatchEvent('initEquation')
})

test('initializes links plugin and renders dialog', function(assert) {
  const done = assert.async()
  this.stub(Links)
  loadEventListeners({
    linksCB: () => {
      ok(Links.renderDialog.calledWithExactly(fakeEditor))
      done()
    }
  })
  return this.dispatchEvent('initLinks')
})

test('builds new image view on RCE event', assert => {
  const done = assert.async()
  assert.expect(1)
  loadEventListeners({
    imagePickerCB: view => {
      ok(view instanceof InsertUpdateImageView)
      done()
    }
  })
  const event = document.createEvent('CustomEvent')
  const eventData = {
    ed: fakeEditor,
    selectNode: '<div></div>'
  }
  event.initCustomEvent('tinyRCE/initImagePicker', true, true, eventData)
  return document.dispatchEvent(event)
})

test('initializes equella plugin', assert => {
  const done = assert.async()
  const alertSpy = sinon.spy(window, 'alert')
  assert.expect(1)
  loadEventListeners({
    equellaCB() {
      ok(
        alertSpy.calledWith(
          'Equella is not properly configured for this account, please notify your system administrator.'
        )
      )
      done()
    }
  })
  const event = document.createEvent('CustomEvent')
  const eventData = {
    ed: fakeEditor,
    selectNode: '<div></div>'
  }
  event.initCustomEvent('tinyRCE/initEquella', true, true, eventData)
  return document.dispatchEvent(event)
})

test('initializes external tools plugin', () => {
  const commandSpy = sinon.spy(fakeEditor, 'addCommand')
  loadEventListeners()
  const event = document.createEvent('CustomEvent')
  const eventData = {
    ed: fakeEditor,
    url: 'someurl.com'
  }
  event.initCustomEvent('tinyRCE/initExternalTools', true, true, eventData)
  document.dispatchEvent(event)
  ok(commandSpy.calledWith('instructureExternalButton__BUTTON_ID__'))
})

test('initializes recording plugin', assert => {
  const done = assert.async()
  const logSpy = sinon.spy(console, 'log')
  assert.expect(1)
  loadEventListeners({
    recordCB() {
      ok(logSpy.calledWith('Kaltura has not been enabled for this account'))
      done()
    }
  })
  const event = document.createEvent('CustomEvent')
  const eventData = {ed: fakeEditor}
  event.initCustomEvent('tinyRCE/initRecord', true, true, eventData)
  return document.dispatchEvent(event)
})
