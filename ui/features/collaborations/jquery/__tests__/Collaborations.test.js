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

import collaborations from '../index'
import $ from 'jquery'
import 'jquery-migrate' // required
import '@canvas/jquery/jquery.ajaxJSON'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const equal = (x, y) => expect(x).toBe(y)

let oldAjaxJSON = null

describe('Collaborations', () => {
  beforeEach(() => {
    oldAjaxJSON = $.ajaxJSON
    const link = $('<a></a>')
    link.addClass('delete_collaboration_link')
    link.attr('href', 'http://test.com')
    const dialog = $('<div id=delete_collaboration_dialog></div>').data('collaboration', link)
    dialog.dialog({
      width: 550,
      height: 500,
      resizable: false,
      modal: true,
      zIndex: 1000,
    })
    const dom = $('<div></div>')
    dom.append(dialog)
    $('#fixtures').append(dom)
  })

  afterEach(() => {
    $('#delete_collaboration_dialog').remove()
    $('#fixtures').empty()
    $.ajaxJSON = oldAjaxJSON
  })

  test('shows a flash message when deletion is complete', () => {
    sandbox.spy($, 'screenReaderFlashMessage')
    const e = {
      originalEvent: MouseEvent,
      type: 'click',
      timeStamp: 1433863761376,
      jQuery17209791898143012077: true,
    }
    $.ajaxJSON = function (url, method, data, callback) {
      const responseData = {}
      return callback.call(responseData)
    }
    collaborations.Events.onDelete(e)
    equal($.screenReaderFlashMessage.callCount, 1)
  })
})
