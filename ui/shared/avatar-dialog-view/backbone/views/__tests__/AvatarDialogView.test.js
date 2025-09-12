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

import $ from 'jquery'
import AvatarDialogView from '../AvatarDialogView'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()
let avatarDialogView

describe('AvatarDialogView#onPreflight', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    window.ENV = {
      folder_id: '1',
      current_user_id: '123',
    }
    avatarDialogView = new AvatarDialogView()
    $.flashError = jest.fn()

    // Mock jQuery.post to use fetch with MSW
    $.post = jest.fn((url, data) => {
      const deferred = $.Deferred()

      fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams(data).toString(),
      })
        .then(response => {
          if (!response.ok) {
            return response.text().then(text => {
              deferred.reject({responseText: text})
            })
          }
          return response.json().then(json => {
            deferred.resolve([json])
          })
        })
        .catch(error => {
          deferred.reject({responseText: error.message})
        })

      return deferred.promise()
    })

    // Mock jQuery.getJSON
    $.getJSON = jest.fn(url => {
      const deferred = $.Deferred()

      fetch(url)
        .then(response => response.json())
        .then(data => deferred.resolve(data))
        .catch(error => deferred.reject(error))

      return deferred.promise()
    })
  })

  afterEach(() => {
    avatarDialogView = null
    $('.ui-dialog').remove()
    server.resetHandlers()
    jest.restoreAllMocks()
    delete window.ENV
  })

  afterAll(() => {
    server.close()
  })

  test('it should be accessible', function (done) {
    isAccessible(avatarDialogView, done, {
      ignores: ['document-title', 'html-has-lang', 'duplicate-id'],
    })
  })

  test('calls flashError with base error message when errors are present', async () => {
    const errorMessage = 'User storage quota exceeded'
    avatarDialogView.enableSelectButton = jest.fn()

    server.use(
      http.post('/files/pending', () => {
        return new HttpResponse(
          JSON.stringify({
            errors: {
              base: errorMessage,
            },
          }),
          {status: 400},
        )
      }),
    )

    // Call the method directly and wait for it to complete
    const result = avatarDialogView.preflightRequest()
    await new Promise(resolve => setTimeout(resolve, 10))

    expect($.flashError).toHaveBeenCalledWith(errorMessage)
    expect(avatarDialogView.enableSelectButton).toHaveBeenCalled()
  })

  test('errors if waitAndSaveUserAvatar is called more than 50 times without successful save', async () => {
    server.use(
      http.get('/api/v1/users/self/avatars', () => {
        return HttpResponse.json([])
      }),
    )

    // Mock handleErrorUpdating
    avatarDialogView.handleErrorUpdating = jest.fn()

    // Directly call with count = 50 to test the error case
    await avatarDialogView.waitAndSaveUserAvatar('fake-token', 'fake-url', 50)

    expect(avatarDialogView.handleErrorUpdating).toHaveBeenCalledWith(
      expect.stringContaining('Profile photo save failed too many times'),
    )
  })
})
