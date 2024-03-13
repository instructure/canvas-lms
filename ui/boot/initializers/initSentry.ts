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

import {configureScope, init, BrowserTracing} from '@sentry/react'
import type {Integration} from '@sentry/types'

export function initSentry() {
  const sentrySettings = ENV.SENTRY_FRONTEND

  // Initialize Sentry as early as possible
  if (sentrySettings?.dsn) {
    const errorsSampleRate = parseFloat(sentrySettings.errors_sample_rate) || 0.0
    const tracesSampleRate = parseFloat(sentrySettings.traces_sample_rate) || 0.0
    const integrations: Integration[] = []
    const denyUrls = sentrySettings.url_deny_pattern
      ? [new RegExp(sentrySettings.url_deny_pattern)]
      : undefined

    if (tracesSampleRate) integrations.push(new BrowserTracing() as Integration)

    init({
      dsn: sentrySettings.dsn,
      environment: ENV.RAILS_ENVIRONMENT,
      release: sentrySettings.revision,

      denyUrls,
      ignoreErrors: ['ChunkLoadError'],
      integrations,

      sampleRate: errorsSampleRate,
      tracesSampleRate,

      initialScope: {
        tags: {k12: ENV.k12, k5_user: ENV.K5_USER, student_user: ENV.current_user_is_student},
        user: {id: ENV.current_user_global_id},
      },
    })

    if (sentrySettings.normalized_route)
      configureScope(scope => scope.setTransactionName(sentrySettings.normalized_route))
  }
}
