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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const server = setupServer()

describe('Collaborations', () => {
  let originalRemoveCollaboration

  beforeAll(() => {
    server.listen()
    fakeENV.setup()
    originalRemoveCollaboration = collaborations.Util.removeCollaboration
    collaborations.Util.removeCollaboration = jest.fn()
  })

  afterEach(() => {
    server.resetHandlers()
    $('#delete_collaboration_dialog').remove()
    $('#fixtures').empty()
  })

  afterAll(() => {
    server.close()
    fakeENV.teardown()
    collaborations.Util.removeCollaboration = originalRemoveCollaboration
  })

  beforeEach(() => {
    $.screenReaderFlashMessage = jest.fn()
    const collaboration = $('<div class="collaboration">')
    collaboration.dim = jest.fn()
    const link = $('<a></a>')
    link.addClass('delete_collaboration_link')
    link.attr('href', 'http://test.com')
    collaboration.append(link)

    const dialog = $('<div id=delete_collaboration_dialog></div>').data(
      'collaboration',
      collaboration,
    )
    dialog.dialog({
      width: 550,
      height: 500,
      resizable: false,
      modal: true,
      zIndex: 1000,
    })
    dialog.dialog = jest.fn()
    const dom = $('<div></div>')
    dom.append(dialog)
    $('#fixtures').append(dom)
  })

  test('shows a flash message when deletion is complete', async () => {
    server.use(
      http.post('http://test.com', () => {
        return HttpResponse.json({})
      }),
    )

    const button = $('<button class="delete_button"></button>')
    const e = {
      originalEvent: MouseEvent,
      type: 'click',
      timeStamp: 1433863761376,
      currentTarget: button[0],
    }

    collaborations.Events.onDelete.call(button[0], e)

    // Wait for the ajax request to complete
    await new Promise(resolve => setTimeout(resolve, 100))

    expect($.screenReaderFlashMessage).toHaveBeenCalledTimes(1)
    expect($.screenReaderFlashMessage).toHaveBeenCalledWith('Collaboration was deleted')
  })
})
