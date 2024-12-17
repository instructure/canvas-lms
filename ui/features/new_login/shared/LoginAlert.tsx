/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('new_login')

interface Props {
  invalidLoginFaqUrl: string | null
  onClose: () => void
  loginHandleName: string
}

function LoginAlert({invalidLoginFaqUrl, onClose, loginHandleName}: Props) {
  if (invalidLoginFaqUrl) {
    const translatedText = I18n.t(
      'Please verify your %{loginHandleName} or password and try again. Trouble logging in? %{faqLink}.',
      {loginHandleName, faqLink: 'ZZZZ_FAQ'}
    )
    const splitText = translatedText.split(/ZZZZ_FAQ/)

    return (
      <Alert
        variant="error"
        hasShadow={false}
        liveRegionPoliteness="assertive"
        isLiveRegionAtomic={true}
        renderCloseButtonLabel={I18n.t('Dismiss error message')}
        onDismiss={onClose}
      >
        <>
          {splitText[0]}
          <Link href={invalidLoginFaqUrl} target="_blank">
            {I18n.t('Check out our Login FAQs')}
          </Link>
          {splitText[1]}
        </>
      </Alert>
    )
  }

  return (
    <Alert
      variant="error"
      hasShadow={false}
      liveRegionPoliteness="assertive"
      isLiveRegionAtomic={true}
      renderCloseButtonLabel={I18n.t('Dismiss error message')}
      onDismiss={onClose}
    >
      {I18n.t('Please verify your %{loginHandleName} or password and try again.', {
        loginHandleName,
      })}
    </Alert>
  )
}

export default LoginAlert
