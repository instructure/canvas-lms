/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import {initFlashContainer} from '../index'

describe('FlashNotifications', () => {
  let holder: HTMLDivElement | null = null
  beforeEach(() => {
    holder = document.createElement('div')
    document.body.appendChild(holder)
    const flashHtml = "<div id='flash_message_holder'/><div id='flash_screenreader_holder'/>"
    holder.innerHTML = flashHtml
    initFlashContainer()
  })
  afterEach(() => {
    if (holder !== null) {
      holder.remove()
    }
  })

  test('text notification', () => {
    $.flashMessage('here is a thing')
    expect(document.querySelector('#flash_message_holder .ic-flash-success')).toHaveTextContent(
      'here is a thing'
    )
  })

  test('html sanitization', () => {
    $.flashWarning('<script>evil()</script>')
    expect(document.querySelector('#flash_message_holder .ic-flash-warning')).toContainHTML(
      '&lt;script&gt;'
    )
  })

  test('html messages', () => {
    $.flashError({html: '<div class="blah">test</div>'})
    expect(
      document.querySelector('#flash_message_holder .ic-flash-error div.blah')
    ).toHaveTextContent('test')
  })

  test('flashErrorSafe with text is the same as flashError', () => {
    $.flashErrorSafe('here is a thing')
    expect(document.querySelector('#flash_message_holder .ic-flash-error')).toHaveTextContent(
      'here is a thing'
    )
  })

  test('flashErrorSafe with "html" escapes HTML', () => {
    $.flashErrorSafe({html: '<script>evil()</script>'})
    expect(document.querySelector('#flash_message_holder .ic-flash-error')).toContainHTML(
      '&lt;script&gt;'
    )
  })

  test('screenreader message', () => {
    $.screenReaderFlashMessage('<script>evil()</script>')
    expect(document.querySelector('#flash_screenreader_holder span')).toContainHTML(
      '&lt;script&gt;'
    )
  })
})
