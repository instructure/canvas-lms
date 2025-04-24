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

const DEV_HOST = 'http://localhost:3002/remoteEntry.js'

// based on https://module-federation.io/docs/en/mf-docs/0.2/dynamic-remotes/
function fetchSpeedGraderLibrary(resolve, reject) {
  const script = document.createElement('script')

  if (!window.REMOTES?.speedgrader) {
    console.debug(`SpeedGrader remote not configured; using ${DEV_HOST}`)
  }
  script.src = window.REMOTES?.speedgrader || DEV_HOST
  script.onload = () => {
    const module = {
      get: request => window.SpeedGraderLibrary.get(request),
      init: arg => {
        try {
          return window.SpeedGraderLibrary.init(arg)
        } catch (e) {
          console.warn('Remote A has already been loaded')
        }
      },
    }
    resolve(module)
  }

  script.onerror = errorEvent => {
    const errorMessage = `Failed to load the script: ${script.src}`
    console.error(errorMessage, errorEvent)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage, errorEvent))
    }
  }

  document.head.appendChild(script)
}

exports.fetchSpeedGraderLibrary = fetchSpeedGraderLibrary

function fetchAnalyticsHub(resolve, reject) {
  const script = document.createElement('script')

  if (!window.REMOTES?.analytics_hub?.launch_url) {
    console.debug(`Analytics Hub remote not configured; using ${DEV_HOST}`)
  }

  script.src = window.REMOTES?.analytics_hub?.launch_url || DEV_HOST
  script.onload = () => {
    const module = {
      get: request => window.AnalyticsHub.get(request),
      init: arg => {
        try {
          return window.AnalyticsHub.init(arg)
        } catch (e) {
          console.warn('Remote A has already been loaded')
        }
      },
    }
    resolve(module)
  }

  script.onerror = errorEvent => {
    const errorMessage = `Failed to load the script: ${script.src}`
    console.error(errorMessage, errorEvent)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage, errorEvent))
    }
  }

  document.head.appendChild(script)
}

exports.fetchAnalyticsHub = fetchAnalyticsHub

function fetchLtiUsage(resolve, reject) {
  const remoteUrl = window.REMOTES?.ltiUsage

  if (!remoteUrl) {
    console.debug(`LTI Usage remote not configured; using ${DEV_HOST}`)
  }

  const script = document.createElement('script')

  script.src = remoteUrl || DEV_HOST

  script.onload = () => {
    const remoteName = 'LtiUsage'

    const module = {
      get: request => window?.[remoteName].get(request),
      init: arg => {
        try {
          return window?.[remoteName].init(arg)
        } catch (e) {
          console.warn(`Remote "${remoteName}" has already been loaded`)
        }
      },
    }
    resolve(module)
  }

  script.onerror = errorEvent => {
    const errorMessage = `Failed to load the script: ${script.src}`

    console.error(errorMessage, errorEvent)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage, errorEvent))
    }
  }

  document.head.appendChild(script)
}

exports.fetchLtiUsage = fetchLtiUsage

function fetchCanvasCareerApp(resolve, reject) {
  const script = document.createElement('script')

  if (!window.REMOTES?.canvascareer) {
    console.debug(`CanvasCareerApp remote not configured; using ${DEV_HOST}`)
  }
  script.src = window.REMOTES?.canvascareer || DEV_HOST
  script.onload = () => {
    const module = {
      get: request => window.CanvasCareerLearningProvider.get(request),
      init: arg => {
        try {
          return window.CanvasCareerLearningProvider.init(arg)
        } catch (e) {
          console.warn('Remote CanvasCareerApp has already been loaded')
        }
      },
    }
    resolve(module)
  }

  script.onerror = errorEvent => {
    const errorMessage = `Failed to load the script: ${script.src}`
    console.error(errorMessage, errorEvent)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage, errorEvent))
    }
  }

  document.head.appendChild(script)
}

exports.fetchCanvasCareerApp = fetchCanvasCareerApp
