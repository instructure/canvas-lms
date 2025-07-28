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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Portal} from '@instructure/ui-portal'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {QRMobileLogin} from './components/QRMobileLogin'

const I18n = createI18nScope('QRMobileLogin')

export function Component(): React.JSX.Element | null {
  const mountPoint = document.getElementById('content')
  if (mountPoint === null) {
    // This should never happen but if it does the user should know
    showFlashAlert({
      message: I18n.t('An error occurred trying to display the QR code'),
      type: 'error',
    })
    return null
  }

  return (
    <Portal open={true} mountNode={mountPoint}>
      <QRMobileLogin withWarning={true} />
    </Portal>
  )
}
