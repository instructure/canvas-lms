#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'compiled/jquery/redirectClickTo'
], ($) ->

  QUnit.module 'redirectClickTo'

  createClick = ->
    e = document.createEvent('MouseEvents')
    e.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, true, false, false, false, 2, null)
    e

  test 'redirects clicks', ->
    sourceDiv = $('<div></div>')
    targetDiv = $('<div></div>')

    targetDivSpy = @spy()
    targetDiv.on 'click', targetDivSpy
    sourceDiv.redirectClickTo(targetDiv)

    e = createClick()
    sourceDiv.get(0).dispatchEvent(e)

    ok targetDivSpy.called, 'click redirected'

    receivedEvent = targetDivSpy.args[0][0]
    equal receivedEvent.type, e.type, 'same event type'
    equal receivedEvent.ctrlKey, e.ctrlKey, 'same ctrl key'
    equal receivedEvent.altKey, e.altKey, 'same alt key'
    equal receivedEvent.shiftKey, e.shiftKey, 'same shift key'
    equal receivedEvent.metaKey, e.metaKey, 'same meta key'
    equal receivedEvent.button, e.button, 'same button'
