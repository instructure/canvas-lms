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

let whenPendoReady: Promise<any> | null = null

export async function initializePendo() {
  if (!whenPendoReady) {
    const result = init()
    if (!result) {
      throw new Error('Pendo not initialized: PENDO_APP_ID missing')
    }

    whenPendoReady = result.catch(error => {
      console.error('Pendo initialization failed:', error)
    })
  }
  return whenPendoReady
}

function init(): Promise<any> | null {
  if (!ENV.PENDO_APP_ID) return null

  // Lazy-load Pendo only when needed (e.g., in browser)
  return import('@pendo/agent').then(({initialize, Replay, VocPortal}) => {
    return initialize({
      apiKey: ENV.PENDO_APP_ID,
      env: 'io',
      visitor: {
        id: ENV.current_user_usage_metrics_id,
        canvasRoles: ENV.current_user_roles,
        locale: ENV.LOCALE || 'en',
      },
      account: {
        id: ENV.DOMAIN_ROOT_ACCOUNT_UUID,
        surveyOptOut: ENV.FEATURES['account_survey_notifications'],
      },
      globalKey: 'canvasUsageMetrics',
      plugins: [Replay, VocPortal],
    })
  })
}

export {whenPendoReady}
export {usePathTransform} from './react/hooks/usePathTransform'
