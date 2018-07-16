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

import collaborations from 'collaborations'
import $ from 'jquery'
import 'jquery.ajaxJSON'

let oldAjaxJSON = null

QUnit.module('Collaborations', {
  setup() {
    oldAjaxJSON = $.ajaxJSON
    const link = $('<a></a>')
    link.addClass('delete_collaboration_link')
    link.attr('href', 'http://test.com')
    const dialog = $('<div id=delete_collaboration_dialog></div>').data('collaboration', link)
    dialog.dialog({
      width: 550,
      height: 500,
      resizable: false
    })
    const dom = $('<div></div>')
    dom.append(dialog)
    $('#fixtures').append(dom)
  },
  teardown() {
    $('#delete_collaboration_dialog').remove()
    $('#fixtures').empty()
    $.ajaxJSON = oldAjaxJSON
  }
})

test('shows a flash message when deletion is complete', function() {
  sandbox.spy($, 'screenReaderFlashMessage')
  const e = {
    originalEvent: MouseEvent,
    type: 'click',
    timeStamp: 1433863761376,
    jQuery17209791898143012077: true
  }
  $.ajaxJSON = function(url, method, data, callback) {
    const responseData = {}
    return callback.call(responseData)
  }
  collaborations.Events.onDelete(e)
  equal($.screenReaderFlashMessage.callCount, 1)
})

test('returns a collaboration url', () => {
  const url = collaborations.Util.collaborationUrl(1)
  equal(url, `${window.location.toString()}/1`)
})

test('it calls updateCollaboration when a service id is in the data parameter', function() {
  sandbox.stub(collaborations.Events, 'updateCollaboration')
  collaborations.Events.onExternalContentReady(
    {},
    {
      service_id: 1,
      contentItems: {}
    }
  )
  equal(collaborations.Events.updateCollaboration.callCount, 1)
})

test('it calls createCollaboration', function() {
  sandbox.stub(collaborations.Events, 'createCollaboration')
  collaborations.Events.onExternalContentReady({}, {contentItems: {}})
  equal(collaborations.Events.createCollaboration.callCount, 1)
})

test('it makes an ajax request to the correct update endpoint', () => {
  const dom = $('<div class="collaboration_1"><a class="title" href="http://url/"></a></div>')
  $('#fixtures').append(dom)
  $.ajaxJSON = (url, method, data, callback) => equal(url, 'http://url/')
  collaborations.Events.onExternalContentReady(
    {},
    {
      service_id: 1,
      contentItems: {}
    }
  )
})
