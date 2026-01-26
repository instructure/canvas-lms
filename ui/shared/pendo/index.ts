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

import {Visitor} from '@pendo/agent'
import {getPrimaryRole} from './utils'

let whenPendoReady: Promise<any> | null = null

export async function initializePendo() {
  if (!whenPendoReady) {
    const result = init()
    if (!result) {
      console.info('Pendo not initialized: PENDO_APP_ID missing')
      whenPendoReady = Promise.resolve(null)
      return whenPendoReady
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
    const visitorData: Visitor = {
      id: ENV.current_user_usage_metrics_id,
      canvasRoles: ENV.current_user_roles,
      locale: ENV.LOCALE || 'en',
    }

    if (ENV.FEATURES?.pendo_extended) {
      visitorData.canvasPrimaryUserRole = getPrimaryRole(ENV.current_user_roles)
      if (ENV.USAGE_METRICS_METADATA) {
        visitorData.canvasSubAccountId = ENV.USAGE_METRICS_METADATA.sub_account_id
        visitorData.canvasSubAccountName = ENV.USAGE_METRICS_METADATA.sub_account_name
        visitorData.canvasCourseId = ENV.USAGE_METRICS_METADATA.course_id
        visitorData.canvasCourseLongName = ENV.USAGE_METRICS_METADATA.course_long_name
        visitorData.canvasCourseSisSourceId = ENV.USAGE_METRICS_METADATA.course_sis_source_id
        visitorData.canvasCourseSisBatchId = ENV.USAGE_METRICS_METADATA.course_sis_batch_id
        visitorData.canvasCourseEnrollmentTermId =
          ENV.USAGE_METRICS_METADATA.course_enrollment_term_id
      }
    }

    return initialize({
      apiKey: ENV.PENDO_APP_ID,
      env: 'io',
      visitor: visitorData,
      account: {
        id: ENV.DOMAIN_ROOT_ACCOUNT_UUID,
        surveyOptOut: !ENV.FEATURES['account_survey_notifications'],
      },
      globalKey: 'canvasUsageMetrics',
      plugins: [Replay, VocPortal],
    })
  })
}

export {whenPendoReady}
export {usePathTransform} from './react/hooks/usePathTransform'
