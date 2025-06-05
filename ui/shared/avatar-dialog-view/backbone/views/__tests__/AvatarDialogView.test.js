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

let avatarDialogView

describe('AvatarDialogView#onPreflight', () => {
  beforeEach(() => {
    avatarDialogView = new AvatarDialogView()
    // Mock jQuery's post and getJSON methods
    $.post = jest.fn()
    $.getJSON = jest.fn()
    $.flashError = jest.fn()
  })

  afterEach(() => {
    avatarDialogView = null
    $('.ui-dialog').remove()
    jest.restoreAllMocks()
  })

  test('it should be accessible', function (done) {
    isAccessible(avatarDialogView, done, {a11yReport: true})
  })

  test('calls flashError with base error message when errors are present', async () => {
    const errorMessage = 'User storage quota exceeded'
    avatarDialogView.enableSelectButton = jest.fn()

    // Mock the failed POST request
    $.post.mockImplementation(() => {
      const deferred = $.Deferred()
      setTimeout(() => {
        deferred.reject({
          responseText: JSON.stringify({
            errors: {
              base: errorMessage,
            },
          }),
        })
      }, 0)
      return deferred.promise()
    })

    // Since preflightRequest doesn't return the promise from $.post for failed requests,
    // we need to wait for the next tick
    avatarDialogView.preflightRequest()
    await new Promise(resolve => setTimeout(resolve, 10))

    expect($.flashError).toHaveBeenCalledWith(errorMessage)
    expect(avatarDialogView.enableSelectButton).toHaveBeenCalled()
  })

  test('errors if waitAndSaveUserAvatar is called more than 50 times without successful save', async () => {
    // Mock getJSON to always return empty array (no processed avatar)
    $.getJSON.mockResolvedValue([])

    // Mock handleErrorUpdating
    avatarDialogView.handleErrorUpdating = jest.fn()

    // Speed up the test by mocking setTimeout
    jest.useFakeTimers()

    const promise = avatarDialogView.waitAndSaveUserAvatar('fake-token', 'fake-url', 0)

    // Run all timers to simulate the 50 retries
    for (let i = 0; i < 50; i++) {
      jest.runOnlyPendingTimers()
      await Promise.resolve() // Let promises settle
    }

    jest.runOnlyPendingTimers()
    await promise

    expect(avatarDialogView.handleErrorUpdating).toHaveBeenCalledWith(
      expect.stringContaining('Profile photo save failed too many times'),
    )

    jest.useRealTimers()
  })
})
