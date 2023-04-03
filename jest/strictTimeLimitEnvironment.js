/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const BaseEnvironment = require('jest-environment-jsdom').default

const CUSTOM_TIMEOUT_LIMIT = 5000
const ABSOLUTE_TIMEOUT = 7500

class StrictTimeLimitEnvironment extends BaseEnvironment {
  async handleTestEvent(event, state) {
    if (process.env.DISABLE_JEST_TIMEOUT_LIMIT === 'true') {
      // Mostly for IDE debuggers that need to change the time limit to allow breakpoints
      return
    }

    if (state.testTimeout > CUSTOM_TIMEOUT_LIMIT) {
      throw new Error(`Custom timeouts cannot exceed the ${CUSTOM_TIMEOUT_LIMIT}ms limit!`)
    } else if ((event.test?.duration || 0) > ABSOLUTE_TIMEOUT) {
      // Jest is supposed to enforce the CUSTOM_TIMEOUT_LIMIT, but it doesn't always for
      // async tests. The duration value is always accurate so just enforce it here.
      throw new Error(
        `Exceeded the absolute ${ABSOLUTE_TIMEOUT}ms runtime limit for spec "${event.test?.name}"!`
      )
    }
  }
}

module.exports = StrictTimeLimitEnvironment
