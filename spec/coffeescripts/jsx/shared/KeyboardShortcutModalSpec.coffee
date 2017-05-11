#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'jsx/shared/KeyboardShortcutModal'
  'react'
  'react-dom'
  'react-addons-test-utils'
], ($, KeyboardShortcutModal, React, ReactDOM, TestUtils) ->

  QUnit.module 'KeyboardShortcutModal#handleKeydown',
    setup: ->
      $('#fixtures').append('<div id="application" />')
      KeyboardShortcutModalElement = React.createElement(KeyboardShortcutModal)
      @component = TestUtils.renderIntoDocument(KeyboardShortcutModalElement)

    teardown: ->
      ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)
      $('#fixtures').empty()

  test  'appears when comma key is pressed', ->
    ok $('.ReactModalPortal').find('.keyboard_navigation').length is 0
    e = new Event('keydown')
    e.which = 188
    document.dispatchEvent(e)
    ok $('.ReactModalPortal').find('.keyboard_navigation').length is 1

  test  'appears when shift + ? is pressed', ->
    ok $('.ReactModalPortal').find('.keyboard_navigation').length is 0
    e = new Event('keydown')
    e.which = 191
    e.shiftKey = true
    document.dispatchEvent(e)
    ok $('.ReactModalPortal').find('.keyboard_navigation').length is 1

  QUnit.module 'KeyboardShortcutModal#render',
    setup: ->
      $('#fixtures').append('<div id="application" />')

    teardown: ->
      ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)
      $('#fixtures').empty()

  test 'renders shortcuts prop', ->
    shortcuts = [
      { keycode: 'a', description: 'Does something cool' }
    ]
    KeyboardShortcutModalElement = React.createElement(KeyboardShortcutModal, { shortcuts: shortcuts, isOpen: true })
    @component = TestUtils.renderIntoDocument(KeyboardShortcutModalElement)
    ok $('.ReactModalPortal').find('.keyboard_navigation').length is 1
    equal $('.ReactModalPortal').find('.keycode').text(), 'a'
    equal $('.ReactModalPortal').find('.description').text(), 'Does something cool'

  test 'renders accessibility cues', ->
    KeyboardShortcutModalElement = React.createElement(KeyboardShortcutModal, { isOpen: true })
    @component = TestUtils.renderIntoDocument(KeyboardShortcutModalElement)
    cue0 = 'Users of screen readers may need to turn off the virtual cursor in order to use these keyboard shortcuts'
    equal $('.ReactModalPortal').find('.keyboard_navigation .screenreader-only:eq(0)').text(), cue0
    cue1 = 'Press the esc key to close this modal'
    equal $('.ReactModalPortal').find('.keyboard_navigation .screenreader-only:eq(1)').text(), cue1
