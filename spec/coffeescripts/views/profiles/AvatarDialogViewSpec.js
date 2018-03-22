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
import AvatarDialogView from 'compiled/views/profiles/AvatarDialogView'
import assertions from 'helpers/assertions'

QUnit.module('AvatarDialogView#onPreflight', {
  setup() {
    this.server = sinon.fakeServer.create()
    this.avatarDialogView = new AvatarDialogView()
  },
  teardown() {
    this.server.restore()
    this.avatarDialogView = null
    $('.ui-dialog').remove()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.avatarDialogView, done, {a11yReport: true})
})

test('calls flashError with base error message when errors are present', function() {
  const errorMessage = 'User storage quota exceeded'
  this.stub(this.avatarDialogView, 'enableSelectButton')
  const mock = this.mock($)
    .expects('flashError')
    .withArgs(errorMessage)
  this.avatarDialogView.preflightRequest()
  this.server.respond('POST', '/files/pending', [
    400,
    {'Content-Type': 'application/json'},
    `{\"errors\":{\"base\":\"${errorMessage}\"}}`
  ])
  ok(mock.verify())
})
