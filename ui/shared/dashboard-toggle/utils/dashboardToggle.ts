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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('dashboard')

export async function toggleDashboardView(enableWidgetDashboard: boolean): Promise<void> {
  const path = `/api/v1/users/${ENV.current_user_id}/settings`

  try {
    const {json} = await doFetchApi<{widget_dashboard_user_preference: boolean}>({
      path,
      method: 'PUT',
      body: {widget_dashboard_user_preference: enableWidgetDashboard},
    })

    if (!json || !('widget_dashboard_user_preference' in json)) {
      throw new Error('Unexpected response from API call')
    }

    if (json.widget_dashboard_user_preference !== enableWidgetDashboard) {
      throw new Error('Dashboard preference was not updated correctly')
    }

    window.location.reload()
  } catch (err) {
    if (err instanceof Error) {
      showFlashAlert({
        message: I18n.t('An error occurred while switching dashboard views'),
        err,
      })
    }
  }
}
