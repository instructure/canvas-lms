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

export default class SinonSandbox {
  constructor(options) {
    this._options = options

    this._options.global.sinon = sinon
  }

  setup() {
    const {global, qunit} = this._options

    this._sandbox = sinon.sandbox.create({
      ...sinon.defaultConfig,
      injectInto: global.sandbox,
      properties: ['clock', 'mock', 'spy', 'stub'],
      useFakeServer: false,
      useFakeTimers: false
    })

    sinon.assert.fail = message => qunit.ok(false, message)
    sinon.assert.pass = message => qunit.ok(true, message)
  }

  teardown() {
    this._sandbox.restore()
  }

  verify() {
    this._sandbox.verify()
  }
}
