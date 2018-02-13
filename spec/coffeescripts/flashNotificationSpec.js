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
import 'compiled/jquery.rails_flash_notifications'

let fixtures = null

QUnit.module('FlashNotifications', {
  setup() {
    fixtures = document.getElementById('fixtures')
    const flashHtml = "<div id='flash_message_holder'/><div id='flash_screenreader_holder'/>"
    fixtures.innerHTML = flashHtml
    return $.initFlashContainer()
  },
  teardown() {
    fixtures.innerHTML = ''
  }
})

test('text notification', () => {
  $.flashMessage('here is a thing')
  ok(
    $('#flash_message_holder .ic-flash-success')
      .text()
      .match(/here is a thing/)
  )
})

test('html sanitization', () => {
  $.flashWarning('<script>evil()</script>')
  ok(
    $('#flash_message_holder .ic-flash-warning')
      .html()
      .match(/&lt;script&gt;/)
  )
})

test('html messages', () => {
  $.flashError({html: '<div class="blah">test</div>'})
  ok(
    $('#flash_message_holder .ic-flash-error div.blah')
      .text()
      .match(/test/)
  )
})

test('screenreader message', () => {
  $.screenReaderFlashMessage('<script>evil()</script>')
  ok(
    $('#flash_screenreader_holder span')
      .html()
      .match(/&lt;script&gt;/)
  )
})
