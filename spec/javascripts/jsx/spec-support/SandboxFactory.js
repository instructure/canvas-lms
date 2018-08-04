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

import SinonSandbox from './sandboxes/SinonSandbox'

export default class SandboxFactory {
  constructor(options) {
    this._options = options

    this._options.global.sandbox = {}

    this._sandboxes = {
      sinon: new SinonSandbox(options)
    }

    this._options.contextTracker.onContextStart(() => {
      this.setup()
    })

    this._options.contextTracker.beforeContextEnd(() => {
      this.verify()
    })

    this._options.contextTracker.onContextEnd(() => {
      this.teardown()
    })
  }

  setup() {
    this._sandboxes.sinon.setup()
  }

  teardown() {
    this._sandboxes.sinon.teardown()
  }

  verify() {
    this._sandboxes.sinon.verify()
  }
}
