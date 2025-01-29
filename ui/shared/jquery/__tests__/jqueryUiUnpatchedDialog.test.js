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
import 'jqueryui/dialog'

describe('Dialog Widget', () => {
  beforeEach(() => {
    document.body.innerHTML =
      '<div id="fixtures"><div id="test-dialog" title="Test Dialog">Test Content</div></div>'
  })

  afterEach(() => {
    $('#test-dialog').dialog('destroy')
    document.body.innerHTML = ''
  })

  it('does not auto-execute button click functions on init', () => {
    const $dialog = $('#test-dialog')
    const openHandler = jest.fn()
    const clickHandler = jest.fn()

    $dialog.dialog({
      open: openHandler,
      buttons: [
        {
          text: 'Re-Lock Modules',
          click: clickHandler,
        },
        {
          text: 'Continue',
          class: 'btn-primary',
        },
      ],
      id: 'relock_modules_dialog',
      title: 'Requirements Changed',
    })

    $dialog.dialog('open')

    expect(openHandler).toHaveBeenCalled()
    expect(clickHandler).not.toHaveBeenCalled()
  })

  it('initializes with correct classes and attributes', () => {
    const $dialog = $('#test-dialog')
    $dialog.dialog({
      modal: true,
      zIndex: 1000,
    })

    $dialog.dialog('open')

    expect($dialog.hasClass('ui-dialog-content')).toBe(true)
    expect($dialog.hasClass('ui-widget-content')).toBe(true)
    expect($dialog.parent().hasClass('ui-corner-all')).toBe(true)
    expect($dialog.parent().attr('role')).toBe('dialog')
  })

  it('triggers open and close events in correct order', () => {
    const $dialog = $('#test-dialog')
    const openHandler = jest.fn()
    const closeHandler = jest.fn(() => {
      expect(openHandler).toHaveBeenCalled()
    })

    $dialog.dialog({
      open: openHandler,
      close: closeHandler,
      modal: true,
      zIndex: 1000,
    })

    $dialog.dialog('open')
    $dialog.dialog('close')

    expect(closeHandler).toHaveBeenCalled()
  })
})
