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

/*
 * This class is deprecated. Tests should use Jest's built-in mocking capabilities:
 * - jest.fn() for creating mock functions
 * - jest.spyOn() for spying on existing methods
 * - jest.mock() for mocking modules
 * - MSW (Mock Service Worker) for network request mocking
 *
 * For more information, see the Canvas JavaScript testing documentation.
 */

export default class SinonSandbox {
  constructor(options) {
    this._options = options

    // Provide compatibility methods on the global object
    if (this._options.global) {
      this._options.global.sandbox = {
        spy: () => () => {},
        stub: () => () => {},
        mock: () => () => {},
        clock: null,
        server: null,
      }
    }
  }

  setup() {
    const {global, qunit} = this._options

    // Mock the sandbox properties with compatibility stubs
    global.sandbox = {
      spy: (obj, method) => {
        const original = obj[method]
        const spy = (...args) => original.apply(obj, args)
        spy.callCount = 0
        spy.called = false
        spy.calledWith = () => false
        spy.restore = () => {
          obj[method] = original
        }
        obj[method] = spy
        return spy
      },
      stub: (obj, method) => {
        const stub = () => {}
        stub.returns = val => {
          obj[method] = () => val
          return stub
        }
        stub.callsFake = fn => {
          obj[method] = fn
          return stub
        }
        stub.restore = () => {}
        if (obj && method) {
          obj[method] = stub
        }
        return stub
      },
      mock: () => ({expects: () => ({returns: () => {}})}),
      clock: null,
      server: {
        respond: () => {},
        respondImmediately: false,
      },
    }

    // Provide compatibility for QUnit assertions if needed
    if (qunit) {
      const mockFn = () => {}
      mockFn.fail = message => qunit.ok(false, message)
      mockFn.pass = message => qunit.ok(true, message)
    }

    // Warn about deprecated usage
    global.sinon = {
      createFakeServer: ({respondImmediately} = {respondImmediately: false}) => {
        console.warn('SinonSandbox is deprecated. Use MSW for network mocking instead.')
        global.sandbox.server.respondImmediately = respondImmediately
        return global.sandbox.server
      },
    }
  }

  teardown() {
    // Clean up any global modifications
    if (this._options.global && this._options.global.sandbox) {
      delete this._options.global.sandbox
    }
  }

  verify() {
    // This is a no-op for compatibility
  }
}
