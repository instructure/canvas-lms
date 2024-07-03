/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import sinon from 'sinon'

/*
 * You might be seeing something like this in your test:
 * WARN LOG: 'You no longer need to manually create and restore a fake server'
 *
 * This means that you have used `sinon.createFakeServer()` to stub xhr calls to
 * the network. You no longer need to create the fake server manually. However,
 * you still need to handle requests made to the network as needed by the code
 * under test.
 *
 * For documentation on faking network requests with sinon, visit:
 * https://sinonjs.org/releases/latest/fake-xhr-and-server/
 */

export default class SinonSandbox {
  constructor(options) {
    this._options = options

    this._options.global.sinon = sinon
  }

  setup() {
    const {global, qunit} = this._options

    this._sandbox = sinon.createSandbox({
      ...sinon.defaultConfig,
      injectInto: global.sandbox,
      properties: ['clock', 'mock', 'server', 'spy', 'stub'],
      useFakeServer: true,
      useFakeTimers: false,
    })

    sinon.assert.fail = message => qunit.ok(false, message)
    sinon.assert.pass = message => qunit.ok(true, message)

    sinon.createFakeServer = ({respondImmediately} = {respondImmediately: false}) => {
      console.warn('You no longer need to manually create and restore a fake server')
      this._sandbox.server.respondImmediately = respondImmediately
      return this._sandbox.server
    }
  }

  teardown() {
    this._sandbox.restore()
  }

  verify() {
    this._sandbox.verify()
  }
}
