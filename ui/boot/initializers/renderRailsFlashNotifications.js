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

import {initFlashContainer, renderServerNotifications} from '@canvas/rails-flash-notifications'
import {configureAlerts} from '@instructure/platform-alerts'
import ready from '@instructure/ready'

export function up() {
  return new Promise((resolve, reject) => {
    ready(() => {
      try {
        initFlashContainer()
        // Configure alerts with initial ENV timeout
        configureAlerts({timeout: window.ENV?.flashAlertTimeout ?? 10000})
        // Intercept writes to ENV.flashAlertTimeout so that dynamic changes
        // (e.g. from selenium tests) immediately reconfigure the timeout.
        // This mirrors the old @canvas/alerts behavior of reading ENV at render time.
        if (window.ENV) {
          let _flashAlertTimeout = window.ENV.flashAlertTimeout
          Object.defineProperty(window.ENV, 'flashAlertTimeout', {
            get() {
              return _flashAlertTimeout
            },
            set(v) {
              _flashAlertTimeout = v
              configureAlerts({timeout: v ?? 10000})
            },
            configurable: true,
          })
        }
      } catch (e) {
        return reject(e)
      }

      setTimeout(function () {
        try {
          renderServerNotifications()
          resolve()
        } catch (e) {
          reject(e)
        }
      }, 100)
    })
  })
}
