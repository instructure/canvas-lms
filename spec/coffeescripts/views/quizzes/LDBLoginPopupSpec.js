/* eslint-disable qunit/no-test-expect-argument */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {defer} from 'lodash'
import $ from 'jquery'
import 'jquery-migrate'
import LDBLoginPopup from 'ui/features/take_quiz/backbone/views/LDBLoginPopup'

let whnd
let popup
let server

QUnit.module('LDBLoginPopup', {
  setup() {
    popup = new LDBLoginPopup({sticky: false})
  },

  teardown() {
    if (server) server.restore()
  },
})

test('it should exec', 1, () => {
  whnd = popup.exec()

  ok(whnd, 'popup window is created')
})

test('it should inject styleSheets', 1, () => {
  whnd = popup.exec()
  strictEqual($(whnd.document).find('link[href]').length, $('link').length)
})

test('it should trigger the @open and @close events', () => {
  const onOpen = sinon.spy()
  const onClose = sinon.spy()

  popup.on('open', onOpen)
  popup.on('close', onClose)

  whnd = popup.exec()
  ok(onOpen.called, '@open handler gets called')

  whnd.close()
  ok(onClose.called, '@close handler gets called')
})

test('it should close after a successful login', 1, () => {
  const onClose = sinon.spy()
  const clock = sinon.useFakeTimers()

  server = sinon.fakeServer.create()
  server.respondWith('POST', /login/, [200, {}, 'OK'])

  popup.on('close', onClose)
  popup.on('open', (e, document) => {
    $(document).find('.btn-primary').trigger('click')
    server.respond()
    clock.tick(1)
    ok(onClose.called, 'popup should be closed')
    clock.restore()
  })

  whnd = popup.exec()
})

test('it should trigger the @login_success event', 1, () => {
  const onSuccess = sinon.spy()
  const clock = sinon.useFakeTimers()

  server = sinon.fakeServer.create()
  server.respondWith('POST', /login/, [200, {}, 'OK'])

  popup.on('login_success', onSuccess)
  popup.on('open', (e, document) => {
    $(document).find('.btn-primary').trigger('click')
    server.respond()
    clock.tick(1)
    ok(onSuccess.called, '@login_success handler gets called')
    clock.restore()
  })

  whnd = popup.exec()
})

test('it should trigger the @login_failure event', 1, () => {
  const onFailure = sinon.spy()

  server = sinon.fakeServer.create()
  server.respondWith('POST', /login/, [401, {}, 'Bad Request'])

  popup.on('login_failure', onFailure)
  popup.on('open', (e, document) => {
    $(document).find('.btn-primary').trigger('click')
    server.respond()
    ok(onFailure.called, '@login_failure handler gets called')
  })

  whnd = popup.exec()
})

test('it should pop back in if student closes it', function (assert) {
  assert.expect(5)
  const done = assert.async()
  let latestWindow
  const onFailure = sinon.spy()
  const onOpen = sinon.spy()
  const onClose = sinon.spy()
  const originalOpen = window.open

  // needed for proper cleanup of windows
  sandbox.stub(window, 'open').callsFake(function () {
    return (latestWindow = originalOpen.apply(this, arguments))
  })

  server = sinon.fakeServer.create()
  server.respondWith('POST', /login/, [401, {}, 'Bad Request'])

  // a sticky version
  popup = new LDBLoginPopup({sticky: true})
  popup.on('login_failure', onFailure)
  popup.on('open', onOpen)
  popup.on('close', onClose)
  popup.one('open', (e, document) => {
    $(document).find('.btn-primary').trigger('click')
    server.respond()
    ok(onFailure.calledOnce, 'logged out by passing in bad credentials')

    defer(() => whnd.close())

    popup.one('close', () =>
      // we need to defer because #open will not be called in the close handler
      defer(() => {
        ok(onOpen.calledTwice, 'popup popped back in')
        ok(onClose.calledOnce, 'popup closed')

        // clean up the dangling window which we don't have a handle to
        popup.off('close.sticky')
        latestWindow.close()
        ok(onClose.calledTwice, 'popup closed for good')
        done()
      })
    )
  })

  whnd = popup.exec()
  ok(onOpen.called, 'popup opened')
})
