/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

const FixedJsdomEnvironment = require('jest-fixed-jsdom')

class CustomExtendedEnvironment extends FixedJsdomEnvironment {
  constructor(config, context) {
    super(config, context)
    this.global.__TEST_FAILED__ = false
  }

  async handleTestEvent(event) {
    if (event.name === 'test_fn_failure') {
      this.global.__TEST_FAILED__ = true
    }

    if (event.name === 'test_done') {
      this.global.__TEST_FAILED__ = false
    }

    // not sure if this is needed, but it is in the original
    if (typeof super.handleTestEvent === 'function') {
      await super.handleTestEvent(event)
    }
  }
}

module.exports = CustomExtendedEnvironment
