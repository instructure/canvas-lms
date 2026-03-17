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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Button} from '@instructure/ui-buttons'
import {useWidgetTheme} from '../theme/WidgetThemeContext'

const I18n = createI18nScope('widget_dashboard')

const DarkModeToggle = () => {
  const {isDark, setIsDark} = useWidgetTheme()
  const [loading, setLoading] = useState(false)
  const path = `/api/v1/users/${ENV.current_user_id}/settings`

  const handleToggle = async () => {
    const newValue = !isDark
    setLoading(true)
    try {
      const {json} = await doFetchApi<{widget_dashboard_dark_mode: boolean}>({
        path,
        method: 'PUT',
        body: {widget_dashboard_dark_mode: newValue},
      })
      if (!json || !('widget_dashboard_dark_mode' in json)) {
        throw new Error('Unexpected response from API call')
      }
      setIsDark(json.widget_dashboard_dark_mode)
    } catch (err) {
      if (err instanceof Error) {
        showFlashAlert({
          message: I18n.t('An error occurred while toggling dark mode'),
          err,
        })
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <Button onClick={handleToggle} disabled={loading} data-testid="dark-mode-toggle">
      {isDark ? I18n.t('Switch to light mode') : I18n.t('Switch to dark mode')}
    </Button>
  )
}

export default DarkModeToggle
