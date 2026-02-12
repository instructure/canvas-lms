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

    if (ENV.FEATURES?.pendo_extended && ENV.USAGE_METRICS_METADATA) {
      const instanceVars = {
        sfId: ENV.DOMAIN_ROOT_ACCOUNT_SFID,
        canvasInstanceDomain: ENV.USAGE_METRICS_METADATA.instance_domain,
      }

      const accountVars = {
        canvasSubAccountId: ENV.USAGE_METRICS_METADATA.sub_account_id,
        canvasSubAccountName: ENV.USAGE_METRICS_METADATA.sub_account_name,
        canvasSubAccountSisId: ENV.USAGE_METRICS_METADATA.sub_account_sis_id,
      }

      const userVars = {
        canvasPrimaryUserRole: getPrimaryRole(ENV.current_user_roles),
        canvasUserId: ENV.USAGE_METRICS_METADATA.user_id,
        canvasUserUuid: ENV.USAGE_METRICS_METADATA.user_uuid,
        canvasUserSisId: ENV.USAGE_METRICS_METADATA.user_sis_id,
        canvasUserDisplayName: ENV.USAGE_METRICS_METADATA.user_display_name,
        canvasUserEmail: ENV.USAGE_METRICS_METADATA.user_email,
        canvasUserTimeZone: ENV.USAGE_METRICS_METADATA.user_time_zone,
      }

      const courseVars = {
        canvasCourseId: ENV.USAGE_METRICS_METADATA.course_id,
        canvasCourseLongName: ENV.USAGE_METRICS_METADATA.course_long_name,
        canvasCourseStatus: ENV.USAGE_METRICS_METADATA.course_status,
        canvasCourseIsBlueprint: ENV.USAGE_METRICS_METADATA.course_is_blueprint,
        canvasCourseIsK5: ENV.USAGE_METRICS_METADATA.course_is_k5,
        canvasCourseHasNoStudents: ENV.USAGE_METRICS_METADATA.course_has_no_students,
        canvasCourseSisSourceId: ENV.USAGE_METRICS_METADATA.course_sis_source_id,
        canvasCourseSisBatchId: ENV.USAGE_METRICS_METADATA.course_sis_batch_id,
        canvasCourseEnrollmentTermId: ENV.USAGE_METRICS_METADATA.course_enrollment_term_id,
        canvasCourseEnrollmentTermName: ENV.USAGE_METRICS_METADATA.course_enrollment_term_name,
        canvasCourseEnrollmentTermSisId: ENV.USAGE_METRICS_METADATA.course_enrollment_term_sis_id,
        canvasCourseEnrollmentTermStartAt:
          ENV.USAGE_METRICS_METADATA.course_enrollment_term_start_at,
        canvasCourseEnrollmentTermEndAt: ENV.USAGE_METRICS_METADATA.course_enrollment_term_end_at,
      }

      Object.assign(visitorData, instanceVars, accountVars, userVars, courseVars)
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
