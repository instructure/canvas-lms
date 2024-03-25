/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

// based on https://module-federation.io/docs/en/mf-docs/0.2/dynamic-remotes/
function fetchSpeedGraderLibrary(resolve, reject) {
  const script = document.createElement('script')
  script.src = window.REMOTES?.speedgrader || 'http://localhost:3002/remoteEntry.js'
  script.onload = () => {
    const module = {
      get: request => window.SpeedGraderLibrary.get(request),
      init: arg => {
        try {
          return window.SpeedGraderLibrary.init(arg)
        } catch (e) {
          // eslint-disable-next-line no-console
          console.warn('Remote A has already been loaded')
        }
      },
    }
    resolve(module)
  }

  script.onerror = errorEvent => {
    const errorMessage = `Failed to load the script: ${script.src}`
    // eslint-disable-next-line no-console
    console.error(errorMessage, errorEvent)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage, errorEvent))
    }
  }

  document.head.appendChild(script)
}

exports.fetchSpeedGraderLibrary = fetchSpeedGraderLibrary
