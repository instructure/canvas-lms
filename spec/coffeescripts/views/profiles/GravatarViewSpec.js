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

import GravatarView from 'compiled/views/profiles/GravatarView'
import assertions from 'helpers/assertions'

QUnit.module('GravatarView', {
  setup() {
    this.oldEnv = window.ENV
    window.ENV = {PROFILE: {primary_email: 'foo@example.com'}}
    this.view = new GravatarView({
      avatarSize: {
        h: 42,
        w: 42
      }
    })
    this.view.$el.appendTo('#fixtures')
    this.view.render()
    this.view.setup()
    this.$preview = this.view.$el.find('.gravatar-preview-image')
    this.$previewButton = this.view.$el.find('.gravatar-preview-btn')
    this.$input = this.view.$el.find('.gravatar-preview-input')
  },
  teardown() {
    window.ENV = this.oldEnv
    this.view.remove()
    if (this.server) this.server.restore()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('pre-populates preview with default', function() {
  const md5 = 'b48def645758b95537d4424c84d1a9ff'
  equal(this.$preview.attr('src'), `https://secure.gravatar.com/avatar/${md5}?s=200&d=identicon`)
})

test('updates preview', function() {
  const md5 = 'e8da7df89c8bcbfec59336b4e0d5e76d'
  this.$input.val('bar@example.com')
  this.$previewButton.click()
  equal(this.$preview.attr('src'), `https://secure.gravatar.com/avatar/${md5}?s=200&d=identicon`)
})

test('calls avatar url with specified size', function() {
  this.server = sinon.fakeServer.create()
  this.server.respond(request => {
    const url_match = request.url.match(/api\/v1\/users\/self/)
    ok(url_match, 'call to unexpected url')
    const body_param = encodeURIComponent('user[avatar][url]')
    const body_match = request.requestBody.match(body_param)
    ok(body_match, 'did not specify avatar url parameter')
    const size_param = encodeURIComponent('s=42')
    const size_match = request.requestBody.match(size_param)
    ok(size_match, 'did not specify correct size')
    request.respond(200, {'Content-Type': 'application/json'}, '{}')
  })
  this.view.updateAvatar()
  this.server.respond()
})
