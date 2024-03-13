/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import 'ui/features/wiki_page_index/jquery/redirectClickTo'

QUnit.module('redirectClickTo')
const createClick = function () {
  const e = document.createEvent('MouseEvents')
  e.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, true, false, false, false, 2, null)
  return e
}
test('redirects clicks', () => {
  const sourceDiv = $('<div></div>')
  const targetDiv = $('<div></div>')
  const targetDivSpy = sinon.spy()
  targetDiv.on('click', targetDivSpy)

  sourceDiv.redirectClickTo(targetDiv)
  const e = createClick()

  sourceDiv.get(0).dispatchEvent(e)

  ok(targetDivSpy.called, 'click redirected')

  const receivedEvent = targetDivSpy.args[0][0]
  equal(receivedEvent.type, e.type, 'same event type')
  equal(receivedEvent.ctrlKey, e.ctrlKey, 'same ctrl key')
  equal(receivedEvent.altKey, e.altKey, 'same alt key')
  equal(receivedEvent.shiftKey, e.shiftKey, 'same shift key')
  equal(receivedEvent.metaKey, e.metaKey, 'same meta key')
  equal(receivedEvent.button, e.button, 'same button')
})
