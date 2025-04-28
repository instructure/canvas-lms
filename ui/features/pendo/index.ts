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

import {initialize, Replay, VocPortal} from '@pendo/agent'

async function initializePendo() {
  const pendo = await initialize({
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
  return pendo
}

initializePendo()
