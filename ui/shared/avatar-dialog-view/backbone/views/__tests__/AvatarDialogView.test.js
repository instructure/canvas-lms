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
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const ok = value => expect(value).toBeTruthy()

let server
let avatarDialogView

describe('AvatarDialogView#onPreflight', () => {
  beforeEach(() => {
    server = sinon.fakeServer.create()
    avatarDialogView = new AvatarDialogView()
  })

  afterEach(() => {
    server.restore()
    avatarDialogView = null
    $('.ui-dialog').remove()
  })

  test('it should be accessible', function (done) {
    isAccessible(avatarDialogView, done, {a11yReport: true})
  })

  // Passes in QUnit, fails in Jest
  test.skip('calls flashError with base error message when errors are present', function () {
    const errorMessage = 'User storage quota exceeded'
    sandbox.stub(avatarDialogView, 'enableSelectButton')
    const mock = sandbox.mock($).expects('flashError').withArgs(errorMessage)
    avatarDialogView.preflightRequest()
    server.respond('POST', '/files/pending', [
      400,
      {'Content-Type': 'application/json'},
      `{\"errors\":{\"base\":\"${errorMessage}\"}}`,
    ])
    ok(mock.verify())
  })

  test('errors if waitAndSaveUserAvatar is called more than 50 times without successful save', function (done) {
    sandbox
      .mock($)
      .expects('getJSON')
      .returns(Promise.resolve([{token: 'avatar-token'}]))
    const mock = sandbox.mock(avatarDialogView).expects('handleErrorUpdating')
    const maxCalls = 50
    avatarDialogView
      .waitAndSaveUserAvatar('fake-token', 'fake-url', maxCalls)
      .then(() => {
        ok(mock.verify())
        done()
      })
      .catch(done)
  })
})
