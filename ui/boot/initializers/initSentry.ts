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

import {init} from '@sentry/react'

export function initSentry() {
  const sentrySettings = ENV.SENTRY_FRONTEND

  // Initialize Sentry as early as possible
  if (sentrySettings?.dsn) {
    const errorSampleRate = parseFloat(sentrySettings.error_sample_rate || 0.0)

    init({
      dsn: sentrySettings.dsn,
      environment: sentrySettings.environment,
      release: sentrySettings.revision,

      sampleRate: Number.isNaN(errorSampleRate) ? 0.0 : errorSampleRate,

      initialScope: {
        tags: {k12: ENV.k12, k5_user: ENV.K5_USER, student_user: ENV.current_user_is_student},
        user: {id: ENV.current_user_global_id}
      }
    })
  }
}
