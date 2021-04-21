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

/**
 * This class acts as a store/registry of sorts.  This enables us to
 * talk between the UI components of the RCE and the API pieces.
 *
 * @class AlertHandler
 */
export class AlertHandler {
  constructor(alertFunc) {
    this.alertFunc = alertFunc
  }

  /**
   * Calls the registered alertFunc assuming one has been set, otherwise
   * it throws.
   *
   * @memberof AlertHandler
   */
  handleAlert = alert => {
    if (this.alertFunc == null) {
      throw new Error('Tried to alert without alertFunc being set first')
    }
    this.alertFunc(alert)
  }
}

export default new AlertHandler()
