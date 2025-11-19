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

function fetchIgniteAgentLibrary(resolve, reject) {
  const remoteUrl = window.REMOTES?.ignite_agent?.launch_url

  if (!remoteUrl) {
    const errorMessage = '[Ignite Agent] Remote not configured, agent can not be loaded'
    console.error(errorMessage)
    if (typeof reject === 'function') {
      reject(new Error(errorMessage))
    }
    return
  }

  const script = document.createElement('script')

  script.src = remoteUrl
  script.onload = () => {
    const module = {
      get: request => window.IgniteAgentLibrary.get(request),
      init: arg => {
        try {
          return window.IgniteAgentLibrary.init(arg)
        } catch (e) {
          console.warn('Remote Ignite Agent has already been loaded')
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

exports.fetchIgniteAgentLibrary = fetchIgniteAgentLibrary

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

function fetchCanvasCareerLearningProviderApp(resolve, reject) {
  const script = document.createElement('script')

  if (!window.REMOTES?.canvas_career_learning_provider) {
    console.debug(`canvas_career_learning_provider remote not configured; using ${DEV_HOST}`)
  }
  script.src = window.REMOTES?.canvas_career_learning_provider || DEV_HOST
  script.onload = () => {
    const module = {
      get: request => window.CanvasCareerLearningProvider.get(request),
      init: arg => {
        try {
          return window.CanvasCareerLearningProvider.init(arg)
        } catch (e) {
          console.warn('Remote canvas_career_learning_provider has already been loaded')
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

exports.fetchCanvasCareerLearningProviderApp = fetchCanvasCareerLearningProviderApp

function fetchCanvasCareerLearnerApp(resolve, reject) {
  const script = document.createElement('script')

  if (!window.REMOTES?.canvas_career_learner) {
    console.debug(`canvas_career_learner remote not configured; using ${DEV_HOST}`)
  }
  script.src = window.REMOTES?.canvas_career_learner || DEV_HOST
  script.onload = () => {
    const module = {
      get: request => window.CanvasCareerLearner.get(request),
      init: arg => {
        try {
          return window.CanvasCareerLearner.init(arg)
        } catch (e) {
          console.warn('Remote canvas_career_learner has already been loaded')
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

exports.fetchCanvasCareerLearnerApp = fetchCanvasCareerLearnerApp

function fetchNewQuizzesApp(resolve, reject) {
  const remoteUrl = window.REMOTES?.new_quizzes?.launch_url

  if (!remoteUrl) {
    console.debug(`new_quizzes remote not configured; using ${DEV_HOST}`)
  }

  const script = document.createElement('script')

  script.src = remoteUrl || DEV_HOST
  script.onload = () => {
    if (!window.NewQuizzes) {
      reject(new Error('NewQuizzes failed to load.'))
      return
    }

    const module = {
      get: request => window.NewQuizzes.get(request),
      init: arg => {
        try {
          return window.NewQuizzes.init(arg)
        } catch (e) {
          console.warn('Remote new_quizzes has already been loaded')
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

exports.fetchNewQuizzesApp = fetchNewQuizzesApp
