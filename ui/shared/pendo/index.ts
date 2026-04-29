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

import {PendoConfig, Visitor} from '@pendo/agent'
import {getPrimaryRole} from './utils'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

declare global {
  interface Window {
    CANVAS_COOKIE_CONSENT_STATE: boolean | null
    CANVAS_DEBUGTAP: any
  }
}
declare const ENV: GlobalEnv

const oneTrustPerformanceCookieClass: string = 'C0002'
const isDevEnv: boolean = ENV && ENV.RAILS_ENVIRONMENT === 'development'

let libraryInitialized: boolean = false
let whenPendoReady: Promise<any> | null = null
let pendoInitializing: boolean = false
let pendoInitParams: PendoConfig | null = null
let thePendo: any = null
let debuglog: (msg: string) => void

function initializeLib(): void {
  if (!libraryInitialized) {
    libraryInitialized = true

    if (isDevEnv) {
      debuglog = (message: string) => {
        console.log(message)
      }
      if (!window.CANVAS_DEBUGTAP) {
        window.CANVAS_DEBUGTAP = {}
      }
      window.CANVAS_DEBUGTAP.testPendoConsentChange = (state: boolean) => {
        const event = new CustomEvent('OneTrustGroupsUpdated', {
          detail: state ? [oneTrustPerformanceCookieClass] : [],
        })
        window.dispatchEvent(event)
      }
    } else {
      debuglog = (_message: string) => {}
    }

    window.addEventListener('OneTrustGroupsUpdated', (e: any) => {
      if (e.detail.includes(oneTrustPerformanceCookieClass)) {
        window.CANVAS_COOKIE_CONSENT_STATE = true
        debuglog('User consented to cookies via OneTrust.')
        if (!pendoInitializing && !thePendo) {
          debuglog('Initializing Pendo for the first time.')
          initializePendo()
        } else if (!pendoInitializing && thePendo && !thePendo.isReady()) {
          debuglog('Restarting Pendo.')
          thePendo.initialize(pendoInitParams)
          whenPendoReady = Promise.resolve(thePendo)
        }
      } else {
        window.CANVAS_COOKIE_CONSENT_STATE = false
        debuglog('User revoked cookie consent via OneTrust.')
        if (pendoInitializing && whenPendoReady) {
          debuglog('Pendo is still initializing, will teardown once ready.')
          whenPendoReady.then(() => {
            debuglog('Pendo finished initializing, now tearing down due to revoked consent.')
            thePendo?.teardown()
            whenPendoReady = Promise.resolve(null)
          })
        } else if (thePendo && thePendo.isReady()) {
          debuglog('Tearing down Pendo immediately due to revoked consent.')
          thePendo.teardown()
          whenPendoReady = Promise.resolve(null)
        }
      }
    })
  }
}

export async function initializePendo() {
  initializeLib()

  if (window.CANVAS_COOKIE_CONSENT_STATE !== true) {
    debuglog('User has not consented to cookies. Pendo will not be initialized.')
    return Promise.resolve(null)
  }

  if (!whenPendoReady) {
    pendoInitializing = true
    const result = init()

    if (!result) {
      pendoInitializing = false
      console.info('Pendo not initialized: PENDO_APP_ID missing')
      whenPendoReady = Promise.resolve(null)
      return whenPendoReady
    }

    whenPendoReady = result
      .then((pendoo: any) => {
        thePendo = pendoo
        if (isDevEnv) {
          window.CANVAS_DEBUGTAP.pendoInstance = pendoo
        }
        pendoInitializing = false
        debuglog('Pendo initialized successfully.')
        return pendoo
      })
      .catch(error => {
        pendoInitializing = false
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

    const accountData: {
      id: string
      surveyOptOut: boolean
      oemAccountId?: string | null
    } = {
      id: ENV.DOMAIN_ROOT_ACCOUNT_UUID,
      surveyOptOut: !ENV.FEATURES['account_survey_notifications'],
    }

    if (ENV.USAGE_METRICS_METADATA?.oem_account_id) {
      accountData.oemAccountId = ENV.USAGE_METRICS_METADATA.oem_account_id
    }

    pendoInitParams = {
      apiKey: ENV.PENDO_APP_ID,
      env: ENV.PENDO_APP_ENV,
      visitor: visitorData,
      account: accountData,
      globalKey: 'canvasUsageMetrics',
      plugins: [Replay, VocPortal],
    }

    return initialize(pendoInitParams)
  })
}

export {whenPendoReady}
export {usePathTransform} from './react/hooks/usePathTransform'
