/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import fetchMock from 'fetch-mock'

/*
 * You might be seeing something like this in your test:
 * ERROR LOG: 'Unexpected fetch with path "/some/url". …'
 *
 * This means that you have not mocked one or more `fetch()` calls occurring
 * during the lifecycle of a test. You need to mock this request like so:
 *
 * sandbox.fetch.mock('path:/some/url', 200)
 *
 * Other mocking forms are available. For more documentation on fetch-mock, the
 * library we are using for testing `fetch`, visit:
 * http://www.wheresrhys.co.uk/fetch-mock/
 */

const ALLOWED_URL_REGEXES = [new RegExp('^https://sentry.insops.net')]

export default class FetchSandbox {
  constructor(options) {
    this._options = options

    this._fetchMock = fetchMock.sandbox()
    this._options.global.sandbox.fetch = this._fetchMock
  }

  setup() {
    const {global, qunit} = this._options
    const {_fetchMock} = this
    const {fetch: fetchReal} = global

    global.fetch = function fetch(...args) {
      if (ALLOWED_URL_REGEXES.some(regex => regex.test(args[0]))) {
        return fetchReal(...args)
      }

      return _fetchMock.call(_fetchMock, ...args)
    }

    // NEVER TOUCH THE NETWORK IN SPECS
    this._fetchMock.config.fallbackToNetwork = false

    this._fetchMock.catch(requestPath => {
      const test = qunit.config.current
      test.pushFailure(
        `Unexpected fetch with path "${requestPath}". This probably means you made an unmocked \`fetch\` request in your tests. See the fetch-mock docs (http://www.wheresrhys.co.uk/fetch-mock/#api-mockingmock) for how to mock this request.`
      )
    })
  }

  teardown() {
    this._fetchMock.resetBehavior()
  }

  verify() {}
}
