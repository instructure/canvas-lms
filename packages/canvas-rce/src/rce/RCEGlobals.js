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

const isEmpty = obj => Object.keys(obj).length === 0

class RCEGlobals {
  constructor() {
    if (!RCEGlobals.instance) {
      RCEGlobals.instance = this
      this._data = {
        features: {},
        config: {},
      }
    }

    return RCEGlobals.instance
  }

  getFeatures() {
    return this._data.features
  }

  setFeatures(features) {
    // Set only once
    if (isEmpty(this._data.features)) {
      this._data.features = {...features}
      Object.freeze(this._data.features)
    }
  }

  getConfig() {
    return this._data.config
  }

  setConfig(config) {
    // Set only once
    if (isEmpty(this._data.config)) {
      this._data.config = {...config}
      Object.freeze(this._data.config)
    }
  }
}

const instance = new RCEGlobals()

export default instance
