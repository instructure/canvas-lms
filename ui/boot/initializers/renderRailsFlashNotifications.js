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
import ready from '@instructure/ready'

export function up() {
  return new Promise((resolve, reject) => {
    ready(() => {
      try {
        initFlashContainer()
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
