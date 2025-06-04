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

import {CondensedButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useNewLogin, useNewLoginData} from '../context'
import React from 'react'
import {assignLocation} from '@canvas/util/globalUtils'

const I18n = createI18nScope('new_login')

type Props = {
  url: string | null
}

const LoginTroubleLink = ({url}: Props) => {
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode} = useNewLoginData()

  if (!url) return null

  const isDisabled = isPreviewMode || isUiActionPending

  return (
    <CondensedButton
      data-testid="login-trouble-link"
      href={url}
      onClick={event => {
        event.preventDefault()
        if (!isDisabled) assignLocation(url)
      }}
    >
      {I18n.t('Trouble logging in?')}
    </CondensedButton>
  )
}

export default LoginTroubleLink
